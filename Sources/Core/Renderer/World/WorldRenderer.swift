import Foundation
import MetalKit
import FirebladeMath
import DeltaCore

/// A renderer that renders a `World` along with its associated entities (from `Game.nexus`).
public final class WorldRenderer: Renderer {
  // MARK: Private properties

  /// Internal renderer for rendering entities.
  private var entityRenderer: EntityRenderer

  /// Render pipeline used for rendering world geometry.
  private var renderPipelineState: MTLRenderPipelineState
  #if !os(tvOS)
  /// Render pipeline used for rendering translucent world geometry.
  private var transparencyRenderPipelineState: MTLRenderPipelineState
  /// Render pipeline used for compositing translucent geometry onto the screen buffer.
  private var compositingRenderPipelineState: MTLRenderPipelineState
  #endif

  /// The device used for rendering.
  private var device: MTLDevice
  /// The resources to use for rendering blocks.
  private var resources: ResourcePack.Resources
  /// The command queue used for rendering.
  private var commandQueue: MTLCommandQueue
  /// The Metal texture palette containing the array-texture and animation-related buffers.
  private var texturePalette: MetalTexturePalette
  /// The light map texture used to calculate rendered brightness.
  private var lightMap: LightMap

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

  /// A buffer containing the light map (updated each frame).
  private var lightMapBuffer: MTLBuffer?

  #if !os(tvOS)
  /// The depth stencil state used for order independent transparency (which requires read-only
  /// depth).
  private let readOnlyDepthState: MTLDepthStencilState
  #endif
  /// The depth stencil state used when order independent transparency is disabled.
  private let depthState: MTLDepthStencilState

  /// The buffer for the uniforms used to render distance fog.
  private let fogUniformsBuffer: MTLBuffer

  private let destroyOverlayRenderPipelineState: MTLRenderPipelineState

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
    let transparentFragmentFunction = try MetalUtil.loadFunction("chunkOITFragmentShader", from: library)
    let transparentCompositingVertexFunction = try MetalUtil.loadFunction(
      "chunkOITCompositingVertexShader",
      from: library
    )
    let transparentCompositingFragmentFunction = try MetalUtil.loadFunction(
      "chunkOITCompositingFragmentShader",
      from: library
    )

    // Create block palette array texture.
    resources = client.resourcePack.vanillaResources
    texturePalette = try MetalTexturePalette(
      palette: resources.blockTexturePalette,
      device: device,
      commandQueue: commandQueue
    )

    // Create light map
    lightMap = LightMap(ambientLight: Double(client.game.world.dimension.ambientLight))

    // TODO: Have another copy of this pipeline without blending enabled (to use when OIT is enabled)
    // Create opaque pipeline (which also handles translucent geometry when OIT is disabled)
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "WorldRenderer.mainPipeline",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: true
    )

    destroyOverlayRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "WorldRenderer.destroyOverlayPipeline",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: true,
      editDescriptor: { descriptor in
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationColor
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .sourceColor
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
      }
    )

    #if !os(tvOS)
    // Create OIT pipeline
    transparencyRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "WorldRenderer.oit",
      vertexFunction: vertexFunction,
      fragmentFunction: transparentFragmentFunction,
      blendingEnabled: true,
      editDescriptor: { (descriptor: MTLRenderPipelineDescriptor) in
        // Accumulation texture
        descriptor.colorAttachments[1].isBlendingEnabled = true
        descriptor.colorAttachments[1].rgbBlendOperation = .add
        descriptor.colorAttachments[1].alphaBlendOperation = .add
        descriptor.colorAttachments[1].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[1].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[1].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[1].destinationAlphaBlendFactor = .one

        // Revealage texture
        descriptor.colorAttachments[2].isBlendingEnabled = true
        descriptor.colorAttachments[2].rgbBlendOperation = .add
        descriptor.colorAttachments[2].alphaBlendOperation = .add
        descriptor.colorAttachments[2].sourceRGBBlendFactor = .zero
        descriptor.colorAttachments[2].sourceAlphaBlendFactor = .zero
        descriptor.colorAttachments[2].destinationRGBBlendFactor = .oneMinusSourceColor
        descriptor.colorAttachments[2].destinationAlphaBlendFactor = .oneMinusSourceAlpha
      }
    )

    // Create OIT compositing pipeline
    compositingRenderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "WorldRenderer.compositing",
      vertexFunction: transparentCompositingVertexFunction,
      fragmentFunction: transparentCompositingFragmentFunction,
      blendingEnabled: true
    )

    // Create the depth state used for order independent transparency
    readOnlyDepthState = try MetalUtil.createDepthState(device: device, readOnly: true)
    #endif

    // Create the regular depth state.
    // TODO: Is this meant to be read only? I would assume not
    depthState = try MetalUtil.createDepthState(device: device, readOnly: true)

    // Create entity renderer
    entityRenderer = try EntityRenderer(
      client: client,
      device: device,
      commandQueue: commandQueue,
      profiler: profiler
    )

    // Create world mesh
    worldMesh = WorldMesh(client.game.world, resources: resources)

    // TODO: Improve storage mode selection
    #if os(macOS)
      let storageMode = MTLResourceOptions.storageModeManaged
    #elseif os(iOS) || os(tvOS)
      let storageMode = MTLResourceOptions.storageModeShared
    #else
      #error("Unsupported platform")
    #endif

    var identityUniforms = ChunkUniforms()
    identityUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      bytes: &identityUniforms,
      length: MemoryLayout<ChunkUniforms>.stride,
      options: storageMode
    )

    let maxOutlinePartCount = RegistryStore.shared.blockRegistry.blocks.map { block in
      return block.shape.outlineShape.aabbs.count
    }.max() ?? 1

    let geometry = Self.generateOutlineGeometry(position: .zero, size: [1, 1, 1], baseIndex: 0)

    blockOutlineIndexBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<UInt32>.stride * geometry.indices.count * maxOutlinePartCount,
      options: storageMode,
      label: "blockOutlineIndexBuffer"
    )

    blockOutlineVertexBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<BlockVertex>.stride * geometry.vertices.count * maxOutlinePartCount,
      options: storageMode,
      label: "blockOutlineVertexBuffer"
    )

    fogUniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<FogUniforms>.stride,
      options: storageMode,
      label: "fogUniformsBuffer"
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
    texturePalette.update()
    profiler.pop()

    // Get light map buffer
    profiler.push(.updateLightMap)
    lightMap.update(
      tick: client.game.tickScheduler.tickNumber,
      sunAngleRadians: client.game.world.getSunAngleRadians(),
      ambientLight: Double(client.game.world.dimension.ambientLight),
      dimensionHasSkyLight: client.game.world.dimension.hasSkyLight
    )
    lightMapBuffer = try lightMap.getBuffer(device, reusing: lightMapBuffer)
    profiler.pop()

    profiler.push(.updateFogUniforms)
    var fogUniforms = Self.fogUniforms(client: client, camera: camera)
    fogUniformsBuffer.contents().copyMemory(
      from: &fogUniforms,
      byteCount: MemoryLayout<FogUniforms>.stride
    )
    profiler.pop()

    // Setup render pass. The instance uniforms (vertex buffer index 3) are set to the identity
    // matrix because this phase of the renderer doesn't use instancing although the chunk shader
    // does support it.
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setVertexBuffer(texturePalette.textureStatesBuffer, offset: 0, index: 3)
    encoder.setFragmentTexture(texturePalette.arrayTexture, index: 0)
    encoder.setFragmentBuffer(lightMapBuffer, offset: 0, index: 0)
    encoder.setFragmentBuffer(texturePalette.timeBuffer, offset: 0, index: 1)
    encoder.setFragmentBuffer(fogUniformsBuffer, offset: 0, index: 2)

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

    if client.game.currentGamemode() != .spectator {
      // Render selected block outline
      profiler.push(.encodeBlockOutline)
      if let (targetedBlockPosition, _, _, _) = client.game.targetedBlock() {
        var indices: [UInt32] = []
        var vertices: [BlockVertex] = []
        let block = client.game.world.getBlock(at: targetedBlockPosition)
        let boundingBox = block.shape.outlineShape.offset(by: targetedBlockPosition.doubleVector)

        if !boundingBox.aabbs.isEmpty {
          for aabb in boundingBox.aabbs {
            let geometry = Self.generateOutlineGeometry(
              position: Vec3f(aabb.position),
              size: Vec3f(aabb.size),
              baseIndex: UInt32(indices.count)
            )
            indices.append(contentsOf: geometry.indices)
            vertices.append(contentsOf: geometry.vertices)
          }

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
            indexBufferOffset: 0
          )
        }
      }
      profiler.pop()
    }

    for breakingBlock in client.game.world.getBreakingBlocks() {
      guard let stage = breakingBlock.stage else {
        continue
      }
      let block = client.game.world.getBlock(at: breakingBlock.position)
      if var model = resources.blockModelPalette.model(for: block.id, at: breakingBlock.position) {
        let textureId = client.resourcePack.vanillaResources.blockTexturePalette.textureIndex(for: Identifier(namespace: "minecraft", name: "block/destroy_stage_\(stage)"))!
        for (i, part) in model.parts.enumerated() {
          for (j, element) in part.elements.enumerated() {
            model.parts[i].elements[j].shade = false
            for k in 0..<element.faces.count {
              model.parts[i].elements[j].faces[k].texture = textureId
              model.parts[i].elements[j].faces[k].isTinted = false
            }
          }
        }
        model.textureType = .transparent
        // No clue why light level 12 is the right one, vanilla seems to use light level 15 here but that
        // just doesn't work for us at all (way too bright).
        let lightLevel = LightLevel(
          sky: 12,
          block: 0
        )
        var neighbourLightLevels: [Direction: LightLevel] = [:]
        for direction in Direction.allDirections {
          neighbourLightLevels[direction] = LightLevel(
            sky: 12,
            block: 0
          )
        }
        let offset = block.getModelOffset(at: breakingBlock.position)
        let modelToWorld = MatrixUtil.translationMatrix(breakingBlock.position.floatVector + offset)
        let builder = BlockMeshBuilder(
          model: model,
          position: breakingBlock.position,
          modelToWorld: modelToWorld,
          culledFaces: [],
          lightLevel: lightLevel,
          neighbourLightLevels: neighbourLightLevels,
          tintColor: Vec3f(repeating: 0),
          blockTexturePalette: resources.blockTexturePalette
        )
        var dummyGeometry = Geometry()
        var geometry = SortableMeshElement()
        builder.build(into: &dummyGeometry, translucentGeometry: &geometry)
        for i in 0..<geometry.vertices.count {
          geometry.vertices[i].isTransparent = true
        }
        let vertexBuffer = device.makeBuffer(bytes: &geometry.vertices, length: MemoryLayout<BlockVertex>.stride * geometry.vertices.count)
        guard let indexBuffer = device.makeBuffer(bytes: &geometry.indices, length: MemoryLayout<UInt32>.stride * geometry.indices.count) else {
          // No geometry to render
          continue
        }

        encoder.setRenderPipelineState(destroyOverlayRenderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(identityUniformsBuffer, offset: 0, index: 2)

        encoder.drawIndexedPrimitives(
          type: .triangle,
          indexCount: geometry.indices.count,
          indexType: .uint32,
          indexBuffer: indexBuffer,
          indexBufferOffset: 0
        )
      }
    }

    // Entities are rendered before translucent geometry for correct alpha blending behaviour.
    profiler.push(.entities)
    try entityRenderer.render(
      view: view,
      encoder: encoder,
      commandBuffer: commandBuffer,
      worldToClipUniformsBuffer: worldToClipUniformsBuffer,
      camera: camera
    )
    profiler.pop()

    // Setup render pass for encoding translucent geometry after entity rendering pass
    #if os(tvOS)
      encoder.setRenderPipelineState(renderPipelineState)
    #else
      if client.configuration.render.enableOrderIndependentTransparency {
        encoder.setRenderPipelineState(transparencyRenderPipelineState)
        encoder.setDepthStencilState(readOnlyDepthState)
      } else {
        encoder.setRenderPipelineState(renderPipelineState)
      }
    #endif

    encoder.setVertexBuffer(texturePalette.textureStatesBuffer, offset: 0, index: 3)

    encoder.setFragmentTexture(texturePalette.arrayTexture, index: 0)
    encoder.setFragmentBuffer(lightMapBuffer, offset: 0, index: 0)
    encoder.setFragmentBuffer(texturePalette.timeBuffer, offset: 0, index: 1)

    // Render translucent geometry
    profiler.push(.encodeTranslucent)
    try worldMesh.mutateVisibleMeshes(fromBackToFront: true) { _, mesh in
      try mesh.renderTranslucent(
        viewedFrom: camera.position,
        sortTranslucent: !client.configuration.render.enableOrderIndependentTransparency,
        renderEncoder: encoder,
        device: device,
        commandQueue: commandQueue
      )
    }

    // Composite translucent geometry onto the screen buffer. No vertices need to be supplied, the
    // shader has the screen's corners hardcoded for simplicity.
    #if !os(tvOS)
      if client.configuration.render.enableOrderIndependentTransparency {
        encoder.setRenderPipelineState(compositingRenderPipelineState)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.setDepthStencilState(depthState)
      }
    #endif
    profiler.pop()
  }

  // MARK: Private methods

  private func handle(_ event: Event) {
    // TODO: Optimize this the section updating algorithms to minimise unnecessary updates
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
        worldMesh.updateSections(at: Array(affectedSections))

      case let event as World.Event.SingleBlockUpdate:
        let affectedSections = worldMesh.sectionsAffectedBySectionUpdate(at: event.position.chunkSection)
        worldMesh.updateSections(at: Array(affectedSections))

      case let event as World.Event.MultiBlockUpdate:
        var affectedSections: Set<ChunkSectionPosition> = []
        for update in event.updates {
          affectedSections.formUnion(worldMesh.sectionsAffectedBySectionUpdate(at: update.position.chunkSection))
        }
        worldMesh.updateSections(at: Array(affectedSections))

      case let event as World.Event.UpdateChunk:
        var affectedSections: Set<ChunkSectionPosition> = []

        for sectionY in event.updatedSections {
          let position = ChunkSectionPosition(event.position, sectionY: sectionY)
          affectedSections.formUnion(worldMesh.sectionsAffectedBySectionUpdate(at: position))
        }
        worldMesh.updateSections(at: Array(affectedSections))

      case _ as JoinWorldEvent:
        // TODO: this has the possibility to cause crashes
        worldMesh = WorldMesh(client.game.world, resources: resources)

      default:
        return
    }
  }

  static func fogUniforms(client: Client, camera: Camera) -> FogUniforms {
    // When the render distance is above 2, move the fog 1 chunk closer to conceal
    // more of the world edge.
    let renderDistance = max(client.configuration.render.renderDistance - 1, 2)
    let fog = client.game.world.getFog(
      forViewerWithRay: camera.ray,
      withRenderDistance: renderDistance
    )

    let isLinear: Bool
    let fogDensity: Float
    let fogStart: Float
    let fogEnd: Float
    switch fog.style {
      case let .exponential(density):
        isLinear = false
        fogDensity = density
        // Start and end are ignored by exponential fog
        fogStart = 0
        fogEnd = 0
      case let .linear(start, end):
        isLinear = true
        // Density is ignored by linear fog
        fogDensity = 0
        fogStart = start
        fogEnd = end
    }

    return FogUniforms(
      fogColor: fog.color,
      fogStart: fogStart,
      fogEnd: fogEnd,
      fogDensity: fogDensity,
      isLinear: isLinear
    )
  }

  private static func generateOutlineGeometry(
    position: Vec3f,
    size: Vec3f,
    baseIndex: UInt32
  ) -> Geometry {
    let thickness: Float = 0.004
    let padding: Float = -thickness + 0.001

    // swiftlint:disable:next large_tuple
    var boxes: [(position: Vec3f, size: Vec3f, axis: Axis, faces: [Direction])] = []
    for side: Direction in [.north, .east, .south, .west] {
      // Create up-right edge between this side and the next
      let adjacentSide = side.rotated(1, clockwiseFacing: .down)

      var position = side.vector + adjacentSide.vector
      position *= size / 2 + Vec3f(padding + thickness / 2, 0, padding + thickness / 2)
      position += Vec3f(size.x - thickness, 0, size.z - thickness) / 2
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
          size: (Vec3f(1, 1, 1) - edgeDirection) * thickness + edge,
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
          let vertexPosition = (Vec4f(vertex, 1) * transformation).xyz
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
            skyLightLevel: UInt8(LightLevel.maximumLightLevel),
            blockLightLevel: 0,
            textureIndex: UInt16.max,
            isTransparent: false
          ))
        }
      }
    }

    return Geometry(vertices: blockOutlineVertices, indices: blockOutlineIndices)
  }
}
