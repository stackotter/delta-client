import DeltaCore
import FirebladeECS
import FirebladeMath
import Foundation
import MetalKit

/// Renders all entities in the world the client is currently connected to.
public struct EntityRenderer: Renderer {
  /// The color to render hit boxes as. Defaults to 0xe3c28d (light cream colour).
  public static let hitBoxColor = DeltaCore.RGBColor(hexCode: 0xe3c28d)

  /// The render pipeline state for rendering entities. Does not have blending enabled.
  private var renderPipelineState: MTLRenderPipelineState
  /// The buffer containing the uniforms for all rendered entities.
  private var instanceUniformsBuffer: MTLBuffer?
  /// The buffer containing the hit box vertices. They form a basic cube and instanced rendering is used to render the cube once for each entity.
  private var vertexBuffer: MTLBuffer
  /// The buffer containing the index windings for the template hit box (see ``vertexBuffer``.
  private var indexBuffer: MTLBuffer
  /// The number of indices in ``indexBuffer``.
  private var indexCount: Int

  private var entityTexturePalette: MetalTexturePalette

  private var entityModelPalette: EntityModelPalette
  private var itemModelPalette: ItemModelPalette
  private var blockModelPalette: BlockModelPalette

  /// The client that entities will be renderer for.
  private var client: Client
  /// The device that will be used to render.
  private var device: MTLDevice
  /// The command queue used to perform operations outside of the main render loop.
  private var commandQueue: MTLCommandQueue

  private var profiler: Profiler<RenderingMeasurement>

  /// Creates a new entity renderer.
  public init(
    client: Client,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.client = client
    self.device = device
    self.commandQueue = commandQueue
    self.profiler = profiler

    // Load library
    let library = try MetalUtil.loadDefaultLibrary(device)
    let vertexFunction = try MetalUtil.loadFunction("entityVertexShader", from: library)
    let fragmentFunction = try MetalUtil.loadFunction("entityFragmentShader", from: library)

    // Create render pipeline state
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "dev.stackotter.delta-client.EntityRenderer",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: false
    )

    // Create hitbox geometry (hitboxes are rendered using instancing)
    var geometry = Self.createHitBoxGeometry(color: Self.hitBoxColor)
    indexCount = geometry.indices.count

    vertexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &geometry.vertices,
      length: geometry.vertices.count * MemoryLayout<EntityVertex>.stride,
      options: .storageModeShared,
      label: "entityHitBoxVertices"
    )

    indexBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &geometry.indices,
      length: geometry.indices.count * MemoryLayout<UInt32>.stride,
      options: .storageModeShared,
      label: "entityHitBoxIndices"
    )

    entityTexturePalette = try MetalTexturePalette(
      palette: client.resourcePack.vanillaResources.entityTexturePalette,
      device: device,
      commandQueue: commandQueue
    )

    entityModelPalette = client.resourcePack.vanillaResources.entityModelPalette
    itemModelPalette = client.resourcePack.vanillaResources.itemModelPalette
    blockModelPalette = client.resourcePack.vanillaResources.blockModelPalette
  }

  /// Renders all entity hit boxes using instancing.
  public mutating func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    var isFirstPerson = false
    client.game.accessPlayer { player in
      isFirstPerson = player.camera.perspective == .firstPerson
    }

    // Get all renderable entities
    var geometry = Geometry<EntityVertex>()
    client.game.accessNexus { nexus in
      // If the player is in first person view we don't render them
      profiler.push(.getEntities)
      let entities: Family<Requires4<EntityPosition, EntityRotation, EntityHitBox, EntityKindId>>
      if isFirstPerson {
        entities = nexus.family(
          requiresAll: EntityPosition.self,
          EntityRotation.self,
          EntityHitBox.self,
          EntityKindId.self,
          excludesAll: ClientPlayerEntity.self
        )
      } else {
        entities = nexus.family(
          requiresAll: EntityPosition.self,
          EntityRotation.self,
          EntityHitBox.self,
          EntityKindId.self
        )
      }
      profiler.pop()

      let renderDistance = client.configuration.render.renderDistance
      let cameraChunk = camera.entityPosition.chunk

      // Create uniforms for each entity
      profiler.push(.createUniforms)
      for (entity, position, rotation, hitbox, kindId) in entities.entityAndComponents {
        // Don't render entities that are outside of the render distance
        let chunkPosition = position.chunk
        if !chunkPosition.isWithinRenderDistance(renderDistance, of: cameraChunk) {
          continue
        }

        guard var kindIdentifier = kindId.entityKind?.identifier else {
          log.warning("Unknown entity kind '\(kindId.id)'")
          continue
        }

        if kindIdentifier == Identifier(name: "ender_dragon") {
          kindIdentifier = Identifier(name: "dragon")
        }

        let builder = EntityMeshBuilder(
          entity: entity,
          entityKind: kindIdentifier,
          position: Vec3f(position.smoothVector),
          pitch: rotation.smoothPitch,
          yaw: rotation.smoothYaw,
          entityModelPalette: entityModelPalette,
          itemModelPalette: itemModelPalette,
          blockModelPalette: blockModelPalette,
          texturePalette: entityTexturePalette,
          hitbox: hitbox.aabb(at: position.smoothVector)
        )
        builder.build(into: &geometry)
      }
      profiler.pop()
    }

    guard !geometry.isEmpty else {
      return
    }

    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(entityTexturePalette.arrayTexture, index: 0)

    // TODO: Update profiler measurements
    var mesh = Mesh<EntityVertex, Void>(geometry, uniforms: ())
    try mesh.render(into: encoder, with: device, commandQueue: commandQueue)
  }

  /// Creates a coloured and shaded cube to be rendered using instancing as entities' hitboxes.
  private static func createHitBoxGeometry(color: DeltaCore.RGBColor) -> Geometry<EntityVertex> {
    var vertices: [EntityVertex] = []
    var indices: [UInt32] = []

    for direction in Direction.allDirections {
      let faceVertices = CubeGeometry.faceVertices[direction.rawValue]
      for position in faceVertices {
        let color = color.floatVector * CubeGeometry.shades[direction.rawValue]
        vertices.append(
          EntityVertex(
            x: position.x,
            y: position.y,
            z: position.z,
            r: color.x,
            g: color.y,
            b: color.z,
            u: 0,
            v: 0,
            textureIndex: nil
          )
        )
      }

      let offset = UInt32(indices.count / 6 * 4)
      for value in CubeGeometry.faceWinding {
        indices.append(value + offset)
      }
    }

    return Geometry(vertices: vertices, indices: indices)
  }
}
