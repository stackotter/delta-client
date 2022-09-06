import Foundation
import MetalKit
import simd

/// A renderer that renders a `World`
public final class WorldRenderer: Renderer {
  // MARK: Private properties

  /// Render pipeline used for rendering world geometry.
  private var renderPipelineState: MTLRenderPipelineState

  /// The device used for rendering.
  private var device: MTLDevice
  /// The resources to use for rendering blocks.
  private var resources: ResourcePack.Resources
  /// The command queue used for rendering.
  private var commandQueue: MTLCommandQueue
  /// The array texture containing all of the block textures.
  private var arrayTexture: AnimatedArrayTexture

  /// The client to render for.
  private var client: Client

  /// Manages the world's meshes.
  private var worldMesh: WorldMesh

  /// The rendering profiler.
  private var profiler: Profiler<RenderingMeasurement>

  /// A buffer containing uniforms containing the identity matrix (no-op).
  private var identityUniformsBuffer: MTLBuffer

  /// A buffer containing vertices for a block outline.
  private let blockOutlineVertexBuffer: MTLBuffer
  /// A buffer containing indices for a block outline.
  private let blockOutlineIndexBuffer: MTLBuffer

  // MARK: Init

  /// Creates a new world renderer.
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

    // Load shaders
    let library = try MetalUtil.loadDefaultLibrary(device)
    let vertexFunction = try MetalUtil.loadFunction("chunkVertexShader", from: library)
    let fragmentFunction = try MetalUtil.loadFunction("chunkFragmentShader", from: library)

    // Create block palette array texture.
    resources = client.resourcePack.vanillaResources
    arrayTexture = try AnimatedArrayTexture(
      palette: resources.blockTexturePalette,
      device: device,
      commandQueue: commandQueue
    )

    // Create pipeline
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "dev.stackotter.delta-client.WorldRenderer",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: true
    )

    // Create world mesh
    worldMesh = WorldMesh(client.game.world, resources: resources)

    var identityUniforms = Uniforms()
    identityUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &identityUniforms,
      length: MemoryLayout<Uniforms>.stride,
      options: [.storageModeManaged]
    )

    let maxOutlinePartCount = RegistryStore.shared.blockRegistry.blocks.map { block in
      return block.shape.outlineShape.aabbs.count
    }.max() ?? 1

    let geometry = Self.generateOutlineGeometry(position: .zero, size: [1, 1, 1], baseIndex: 0)

    blockOutlineIndexBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<UInt32>.stride * geometry.indices.count * maxOutlinePartCount,
      options: .storageModeManaged,
      label: "blockOutlineIndexBuffer"
    )

    blockOutlineVertexBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<BlockVertex>.stride * geometry.vertices.count * maxOutlinePartCount,
      options: .storageModeManaged,
      label: "blockOutlineVertexBuffer"
    )

    // Register event handler
    client.eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handle(event)
    }
  }

  // MARK: Public methods

  /// Renders the world's blocks.
  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Update world mesh
    profiler.push(.updateWorldMesh)
    worldMesh.update(
      camera: camera,
      renderDistance: client.configuration.render.renderDistance
    )
    profiler.pop()

    // Update animated textures
    profiler.push(.updateAnimatedTextures)
    #if os(macOS)
    // TODO: Figure out why array texture updates perform so terribly on iOS
    arrayTexture.update(
      tick: client.game.tickScheduler.tickNumber,
      device: device,
      commandQueue: commandQueue
    )
    #endif
    profiler.pop()

    // Setup render pass
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    encoder.setVertexBuffer(identityUniformsBuffer, offset: 0, index: 3) // Instance uniforms

    // Render transparent and opaque geometry
    profiler.push(.encodeOpaque)
    try worldMesh.mutateVisibleMeshes { _, mesh in
      try mesh.renderTransparentAndOpaque(
        renderEncoder: encoder,
        device: device,
        commandQueue: commandQueue
      )
    }
    profiler.pop()

    // Render selected block outline
    profiler.push(.encodeBlockOutline)
    if let targetedBlockPosition = client.game.targetedBlock() {
      var indices: [UInt32] = []
      var vertices: [BlockVertex] = []
      let block = client.game.world.getBlock(at: targetedBlockPosition)
      let boundingBox = block.shape.outlineShape.offset(by: targetedBlockPosition.doubleVector)

      for aabb in boundingBox.aabbs {
        let geometry = Self.generateOutlineGeometry(
          position: SIMD3(aabb.position),
          size: SIMD3(aabb.size),
          baseIndex: UInt32(indices.count)
        )
        indices.append(contentsOf: geometry.indices)
        vertices.append(contentsOf: geometry.vertices)
      }

      if !boundingBox.aabbs.isEmpty {
        blockOutlineVertexBuffer.contents().copyMemory(
          from: &vertices,
          byteCount: MemoryLayout<BlockVertex>.stride * vertices.count
        )
        blockOutlineIndexBuffer.contents().copyMemory(
          from: &indices,
          byteCount: MemoryLayout<UInt32>.stride * indices.count
        )

        encoder.setVertexBuffer(blockOutlineVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(identityUniformsBuffer, offset: 0, index: 2)

        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: indices.count,
          indexType: .uint32,
          indexBuffer: blockOutlineIndexBuffer,
          indexBufferOffset: 0,
          instanceCount: 1
        )
      }
    }
    profiler.pop()

    // Render translucent geometry
    profiler.push(.encodeTranslucent)
    try worldMesh.mutateVisibleMeshes(fromBackToFront: true) { _, mesh in
      try mesh.renderTranslucent(
        viewedFrom: camera.position,
        sortTranslucent: true,
        renderEncoder: encoder,
        device: device,
        commandQueue: commandQueue
      )
    }
    profiler.pop()
  }

  // MARK: Private methods

  private func handle(_ event: Event) {
    switch event {
      case let event as World.Event.AddChunk:
        worldMesh.addChunk(at: event.position)

      case let event as World.Event.RemoveChunk:
        worldMesh.removeChunk(at: event.position)

      case let event as World.Event.UpdateChunkLighting:
        let updatedSections = event.data.updatedSections
        var affectedSections: Set<ChunkSectionPosition> = []
        for y in updatedSections {
          let position = ChunkSectionPosition(event.position, sectionY: y)
          let affected = worldMesh.sectionsAffectedBySectionUpdate(at: position, onlyLighting: true)
          affectedSections.formUnion(affected)
        }

        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }

      case let event as World.Event.SetBlock:
        let affectedSections = worldMesh.sectionsAffectedBySectionUpdate(at: event.position.chunkSection)

        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }

      case let event as World.Event.UpdateChunk:
        var affectedSections: Set<ChunkSectionPosition> = []

        for sectionY in event.updatedSections {
          let position = ChunkSectionPosition(event.position, sectionY: sectionY)
          affectedSections.formUnion(worldMesh.sectionsAffectedBySectionUpdate(at: position))
        }

        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }

      case _ as JoinWorldEvent:
        // TODO: this has the possibility to cause crashes
        log.debug("Created new world mesh")
        worldMesh = WorldMesh(client.game.world, resources: resources)

      default:
        return
    }
  }

  private static func generateOutlineGeometry(
    position: SIMD3<Float>,
    size: SIMD3<Float>,
    baseIndex: UInt32
  ) -> Geometry {
    let thickness: Float = 0.004
    let padding: Float = -thickness + 0.001
    var boxes: [(position: SIMD3<Float>, size: SIMD3<Float>, axis: Axis, faces: [Direction])] = []
    for side: Direction in [.north, .east, .south, .west] {
      // Create up-right edge between this side and the next
      let adjacentSide = side.rotated(1, clockwiseFacing: .down)

      var position = side.vector + adjacentSide.vector
      position *= size / 2 + SIMD3(padding + thickness / 2, 0, padding + thickness / 2)
      position += SIMD3(size.x - thickness, 0, size.z - thickness) / 2
      position.y -= padding
      boxes.append((
        position: position,
        size: [thickness, size.component(along: .y) + padding * 2, thickness],
        axis: .y,
        faces: [side, adjacentSide]
      ))

      // Create the edges above and below this side
      for direction: Direction in [.up, .down] {
        let edgeDirection = adjacentSide.axis.positiveDirection.vector
        var edgeSize = size.component(along: adjacentSide.axis) + (padding + thickness) * 2
        if adjacentSide.axis == .x {
          edgeSize -= thickness * 2
        }
        let edge = abs(adjacentSide.vector * edgeSize)

        var position = position
        if direction == .up {
          position.y += size.component(along: .y) + padding * 2
        } else {
          position.y -= thickness
        }
        if position.component(along: adjacentSide.axis) > 0 {
          if adjacentSide.axis == .x {
            position.x -= size.component(along: .x) + padding * 2
          } else {
            position.z -= size.component(along: .z) + padding * 2 + thickness
          }
        } else if adjacentSide.axis == .x {
          position.x += thickness
        }
        var faces = [side, direction]
        if adjacentSide.axis != .x {
          faces.append(contentsOf: [adjacentSide, adjacentSide.opposite])
        }
        boxes.append((
          position: position,
          size: (SIMD3(1, 1, 1) - edgeDirection) * thickness + edge,
          axis: adjacentSide.axis,
          faces: faces
        ))
      }
    }

    var blockOutlineVertices: [BlockVertex] = []
    var blockOutlineIndices: [UInt32] = []

    let translation = MatrixUtil.translationMatrix(position)
    for box in boxes {
      for face in box.faces {
        let offset = UInt32(blockOutlineVertices.count) + baseIndex
        let winding = CubeGeometry.faceWinding.map { index in
          return index + offset
        }

        // Render both front and back faces
        blockOutlineIndices.append(contentsOf: winding)
        blockOutlineIndices.append(contentsOf: winding.reversed())

        let transformation = MatrixUtil.scalingMatrix(box.size) * MatrixUtil.translationMatrix(box.position) * translation
        for vertex in CubeGeometry.faceVertices[face.rawValue] {
          let vertexPosition = simd_make_float3(SIMD4<Float>(vertex, 1) * transformation)
          blockOutlineVertices.append(BlockVertex(
            x: vertexPosition.x,
            y: vertexPosition.y,
            z: vertexPosition.z,
            u: 0,
            v: 0,
            r: 0,
            g: 0,
            b: 0,
            a: 0.6,
            textureIndex: UInt16.max,
            isTransparent: false
          ))
        }
      }
    }

    return Geometry(vertices: blockOutlineVertices, indices: blockOutlineIndices)
  }
}
