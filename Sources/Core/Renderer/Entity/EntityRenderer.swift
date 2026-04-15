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
  /// The render pipeline state for rendering block entities and block item entities.
  private var blockRenderPipelineState: MTLRenderPipelineState
  /// The buffer containing the uniforms for all rendered entities.
  private var instanceUniformsBuffer: MTLBuffer?

  private var entityTexturePalette: MetalTexturePalette
  private var blockTexturePalette: MetalTexturePalette

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

  /// Should get updated each frame via `setVisibleChunks`.
  private var visibleChunks: Set<ChunkPosition> = []

  /// Creates a new entity renderer.
  public init(
    client: Client,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    profiler: Profiler<RenderingMeasurement>,
    blockTexturePalette: MetalTexturePalette
  ) throws {
    self.client = client
    self.device = device
    self.commandQueue = commandQueue
    self.profiler = profiler
    self.blockTexturePalette = blockTexturePalette

    // Load library
    // TODO: Avoid loading library again and again
    let library = try MetalUtil.loadDefaultLibrary(device)
    let vertexFunction = try MetalUtil.loadFunction("entityVertexShader", from: library)
    let fragmentFunction = try MetalUtil.loadFunction("entityFragmentShader", from: library)
    let blockVertexFunction = try MetalUtil.loadFunction("chunkVertexShader", from: library)
    let blockFragmentFunction = try MetalUtil.loadFunction("chunkFragmentShader", from: library)

    // Create render pipeline state
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "EntityRenderer.renderPipelineState",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: false
    )

    // TODO: Consider supporting OIT here too? Probably not of much use cause most block item
    //   entities aren't translucent, and there should never be many instances of them since
    //   item entities merge.
    blockRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "EntityRenderer.blockRenderPipelineState",
      vertexFunction: blockVertexFunction,
      fragmentFunction: blockFragmentFunction,
      blendingEnabled: true
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
    var blockGeometry = Geometry<BlockVertex>()
    var translucentBlockGeometry = SortableMesh(uniforms: ChunkUniforms())
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
      profiler.push(.createRegularEntityMeshes)
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

        let lightLevel = client.game.world.getLightLevel(at: position.block)
        buildEntityMesh(
          entity: entity,
          entityKindIdentifier: kindIdentifier,
          position: Vec3f(position.smoothVector),
          pitch: rotation.smoothPitch,
          yaw: rotation.smoothYaw,
          hitbox: hitbox.aabb(at: position.smoothVector),
          lightLevel: lightLevel,
          into: &geometry,
          blockGeometry: &blockGeometry,
          translucentBlockGeometry: &translucentBlockGeometry
        )
      }
      profiler.pop()

      profiler.push(.createBlockEntityMeshes)
      for chunkPosition in visibleChunks {
        guard let chunk = client.game.world.chunk(at: chunkPosition) else {
          continue
        }

        for blockEntity in chunk.getBlockEntities() {
          let position = blockEntity.position.floatVector + Vec3f(0.5, 0, 0.5)

          let block = chunk.getBlock(at: blockEntity.position.relativeToChunk)
          let direction = block.stateProperties.facing ?? .south

          let lightLevel = client.game.world.getLightLevel(at: blockEntity.position)
          buildEntityMesh(
            entity: nil,
            entityKindIdentifier: blockEntity.identifier,
            position: position,
            pitch: 0,
            yaw: Self.blockEntityYaw(toFace: direction),
            hitbox: AxisAlignedBoundingBox(position: .zero, size: Vec3d(1, 1, 1)),
            lightLevel: lightLevel,
            into: &geometry,
            blockGeometry: &blockGeometry,
            translucentBlockGeometry: &translucentBlockGeometry
          )
        }
      }
      profiler.pop()
    }

    profiler.push(.encodeEntities)
    if !geometry.isEmpty {
      encoder.setRenderPipelineState(renderPipelineState)
      encoder.setFragmentTexture(entityTexturePalette.arrayTexture, index: 0)

      var mesh = Mesh<EntityVertex, Void>(geometry, uniforms: ())
      try mesh.render(into: encoder, with: device, commandQueue: commandQueue)
    }

    if !blockGeometry.isEmpty || !translucentBlockGeometry.isEmpty {
      encoder.setRenderPipelineState(blockRenderPipelineState)
      encoder.setVertexBuffer(blockTexturePalette.textureStatesBuffer, offset: 0, index: 3)
      encoder.setFragmentTexture(blockTexturePalette.arrayTexture, index: 0)

      if !blockGeometry.isEmpty {
        var blockMesh = Mesh<BlockVertex, ChunkUniforms>(blockGeometry, uniforms: ChunkUniforms())
        try blockMesh.render(into: encoder, with: device, commandQueue: commandQueue)
      }

      if !translucentBlockGeometry.isEmpty {
        try translucentBlockGeometry.render(
          viewedFrom: camera.position,
          sort: true,
          encoder: encoder,
          device: device,
          commandQueue: commandQueue
        )
      }
    }
    profiler.pop()
  }

  private func buildEntityMesh(
    entity: Entity? = nil,
    entityKindIdentifier: Identifier,
    position: Vec3f,
    pitch: Float,
    yaw: Float,
    hitbox: AxisAlignedBoundingBox,
    lightLevel: LightLevel,
    into geometry: inout Geometry<EntityVertex>,
    blockGeometry: inout Geometry<BlockVertex>,
    translucentBlockGeometry: inout SortableMesh
  ) {
    var translucentBlockElement = SortableMeshElement()
    EntityMeshBuilder(
      entity: entity,
      entityKind: entityKindIdentifier,
      position: position,
      pitch: pitch,
      yaw: yaw,
      entityModelPalette: entityModelPalette,
      itemModelPalette: itemModelPalette,
      blockModelPalette: blockModelPalette,
      entityTexturePalette: entityTexturePalette.palette,
      blockTexturePalette: blockTexturePalette.palette,
      hitbox: hitbox,
      lightLevel: lightLevel
    ).build(
      into: &geometry,
      blockGeometry: &blockGeometry,
      translucentBlockGeometry: &translucentBlockElement
    )
    translucentBlockGeometry.add(translucentBlockElement)
  }

  /// Computes the yaw required for a block entity to face a given direction.
  private static func blockEntityYaw(toFace direction: Direction) -> Float {
    switch direction {
      case .south, .up, .down:
        return 0
      case .west:
        return .pi / 2
      case .north:
        return .pi
      case .east:
        return -.pi / 2
    }
  }

  /// Sets the chunks that block entities should be rendered from.
  public mutating func setVisibleChunks(_ visibleChunks: Set<ChunkPosition>) {
    self.visibleChunks = visibleChunks
  }
}
