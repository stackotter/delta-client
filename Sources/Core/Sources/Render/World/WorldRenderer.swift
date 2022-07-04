import Foundation
import MetalKit
import simd

/// A renderer that renders a `World`
public final class WorldRenderer {
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
  /// Used to encode render commands in parallel.
  private let dispatchQueue = DispatchQueue(label: "WorldRenderer.dispatchQueue", attributes: [.concurrent])
  /// Used to coordinate render command encoding threads.
  private let dispatchGroup = DispatchGroup()

  // MARK: Init

  /// Creates a new world renderer.
  public init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.device = device
    self.client = client
    self.commandQueue = commandQueue

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
    parallelEncoder: MTLParallelRenderCommandEncoder,
    depthState: MTLDepthStencilState,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    worldMesh.update(camera: camera, renderDistance: client.configuration.render.renderDistance)

    // Update animated textures
    #if os(macOS)
    // TODO: Figure out why array texture updates perform so terribly on iOS
    arrayTexture.update(tick: client.game.tickScheduler.tickNumber, device: device, commandQueue: commandQueue)
    #endif

    let errorLock = ReadWriteLock()
    var meshError: Error?

    // Update world mesh and mesh buffers
    try worldMesh.collectUpdatedMeshes(device: device, commandQueue: commandQueue)

    try worldMesh.accessMeshes { meshes, visibleSections in
      let meshCount = visibleSections.count

      // Encode render commands across multiple threads to reduce cpu time
      let threadCount = 3
      var meshesRemaining = meshCount
      var index = 0
      for i in 0..<threadCount {
        let sliceSize = meshesRemaining / (threadCount - i)
        guard sliceSize != 0 else {
          continue
        }

        meshesRemaining -= sliceSize

        let encoder = try createEncoder(
          from: parallelEncoder,
          depthState: depthState,
          worldUniformsBuffer: worldToClipUniformsBuffer
        )

        let startIndex = index
        let endIndex = startIndex + sliceSize
        dispatchGroup.enter()
        dispatchQueue.async {
          print("\(i): \(endIndex - startIndex)")
          do {
            for j in startIndex..<endIndex {
              let position = visibleSections[j]
              if meshes[position] != nil {
                // It was done this way to prevent copies
                // swiftlint:disable force_unwrapping
                try meshes[position]!.renderTransparentAndOpaque(renderEncoder: encoder)
                // swiftlint:enable force_unwrapping
              }
            }

            encoder.endEncoding()
          } catch {
            log.error("Failed to render mesh: \(error)")
            errorLock.acquireWriteLock()
            meshError = error
            errorLock.unlock()
          }

          self.dispatchGroup.leave()
        }

        index += sliceSize
      }

      // Wait for all threads to finish
      dispatchGroup.wait()
    }

    if let error = meshError {
      throw error
    }

    let translucentEncoder = try createEncoder(
      from: parallelEncoder,
      depthState: depthState,
      worldUniformsBuffer: worldToClipUniformsBuffer
    )

    // Render translucent geometry
    try worldMesh.mutateEachVisibleMesh(fromBackToFront: true, acquireLock: false) { _, mesh in
      try mesh.renderTranslucent(
        viewedFrom: camera.position,
        sortTranslucent: true,
        renderEncoder: translucentEncoder,
        device: self.device,
        commandQueue: self.commandQueue
      )
    }

    translucentEncoder.endEncoding()

  }

  // MARK: Private methods

  private func createEncoder(
    from parallelEncoder: MTLParallelRenderCommandEncoder,
    depthState: MTLDepthStencilState,
    worldUniformsBuffer: MTLBuffer
  ) throws -> MTLRenderCommandEncoder {
    guard let encoder = parallelEncoder.makeRenderCommandEncoder() else {
      throw RenderError.failedToCreateRenderEncoder
    }

    switch client.configuration.render.mode {
      case .normal:
        encoder.setCullMode(.front)
      case .wireframe:
        encoder.setCullMode(.none)
        encoder.setTriangleFillMode(.lines)
    }
    encoder.setDepthStencilState(depthState)
    encoder.setFrontFacing(.counterClockwise)
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    encoder.setVertexBuffer(worldUniformsBuffer, offset: 0, index: 1)

    return encoder
  }

  private func handle(_ event: Event) {
    switch event {
      case let event as World.Event.ChunkComplete:
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
}
