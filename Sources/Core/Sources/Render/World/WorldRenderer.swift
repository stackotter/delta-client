import Foundation
import MetalKit
import simd

/// A renderer that renders a `World`
class WorldRenderer {
  /// Render pipeline used for rendering world geometry.
  var renderPipelineState: MTLRenderPipelineState
  /// Depth stencil.
  var depthState: MTLDepthStencilState
  
  var resources: ResourcePack.Resources
  var blockArrayTexture: MTLTexture
  var blockTexturePaletteAnimationState: TexturePaletteAnimationState
  
  var world: World
  var client: Client
  var chunkRenderers: [ChunkPosition: ChunkRenderer] = [:]
  
  var worldUniformBuffers: [MTLBuffer] = []
  var numWorldUniformBuffers = 3
  var worldUniformBufferIndex = 0
  
  /// A set containing all chunks which are currently preparing.
  var preparingChunks: Set<ChunkPosition> = []
  
  init(device: MTLDevice, world: World, client: Client, resources: ResourcePack.Resources, commandQueue: MTLCommandQueue) throws {
    // Load shaders
    log.info("Loading shaders")
    guard let bundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/DeltaCore_DeltaCore.bundle")) else {
      throw RenderError.failedToGetBundle
    }
    guard let libraryURL = bundle.url(forResource: "default", withExtension: "metallib") else {
      throw RenderError.failedToLocateMetallib
    }
    let library: MTLLibrary
    do {
      library = try device.makeLibrary(URL: libraryURL)
    } catch {
      throw RenderError.failedToCreateMetallib(error)
    }

    guard
      let vertex = library.makeFunction(name: "chunkVertexShader"),
      let fragment = library.makeFunction(name: "chunkFragmentShader")
    else {
      log.critical("Failed to load chunk shaders")
      throw RenderError.failedToLoadShaders
    }
    
    self.world = world
    self.client = client
    self.resources = resources
    
    let blockTexturePalette = resources.blockTexturePalette
    blockTexturePaletteAnimationState = TexturePaletteAnimationState(for: blockTexturePalette)
    blockArrayTexture = try Self.createArrayTexture(palette: blockTexturePalette, animationState: blockTexturePaletteAnimationState, device: device, commandQueue: commandQueue)
    renderPipelineState = try Self.createRenderPipelineState(vertex: vertex, fragment: fragment, device: device)
    depthState = try Self.createDepthState(device: device)
    worldUniformBuffers = try Self.createWorldUniformBuffers(device: device, count: numWorldUniformBuffers)
  }
  
  private static func createWorldUniformBuffers(device: MTLDevice, count: Int) throws -> [MTLBuffer] {
    var buffers: [MTLBuffer] = []
    for _ in 0..<count {
      guard let uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: []) else {
        throw RenderError.failedtoCreateWorldUniformBuffers
      }
      
      uniformBuffer.label = "worldUniformBuffer"
      buffers.append(uniformBuffer)
    }
    return buffers
  }
  
  private static func createDepthState(device: MTLDevice) throws -> MTLDepthStencilState {
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
      log.critical("Failed to create depth stencil state")
      throw RenderError.failedToCreateWorldDepthStencilState
    }
    
    return depthState
  }
  
  private static func createRenderPipelineState(vertex: MTLFunction, fragment: MTLFunction, device: MTLDevice) throws -> MTLRenderPipelineState {
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "dev.stackotter.delta-client.WorldRenderer"
    pipelineStateDescriptor.vertexFunction = vertex
    pipelineStateDescriptor.fragmentFunction = fragment
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    // Setup blending operation
    pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .zero
    
    do {
      return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      log.critical("Failed to create render pipeline state")
      throw RenderError.failedToCreateWorldRenderPipelineState(error)
    }
  }
  
  private static func createArrayTexture(palette: TexturePalette, animationState: TexturePaletteAnimationState, device: MTLDevice, commandQueue: MTLCommandQueue) throws -> MTLTexture {
    do {
      return try palette.createTextureArray(
        device: device,
        animationState: animationState,
        commandQueue: commandQueue)
    } catch {
      log.critical("Failed to create texture array: \(error)")
      throw RenderError.failedToCreateBlockTextureArray(error)
    }
  }
  
  /// Handles a batch of world events.
  func handle(_ events: [Event]) {
    var sectionsToUpdate: Set<ChunkSectionPosition> = []
    
    events.forEach { event in
      switch event {
        case let event as World.Event.AddChunk:
          handleAddChunk(event)
        case let event as World.Event.RemoveChunk:
          handleRemoveChunk(event)
        case let chunkLightingUpdate as World.Event.UpdateChunkLighting:
          handleLightingUpdate(chunkLightingUpdate)
        case let blockUpdate as World.Event.SetBlock:
          let affectedSections = sectionsAffected(by: blockUpdate)
          sectionsToUpdate.formUnion(affectedSections)
        case let chunkUpdate as World.Event.UpdateChunk:
          // TODO: only remesh updated chunks
          for sectionIndex in 0..<16 {
            let sectionPosition = ChunkSectionPosition(chunkUpdate.position, sectionY: sectionIndex)
            let neighbours = sectionsNeighbouring(sectionAt: sectionPosition)
            sectionsToUpdate.formUnion(neighbours)
          }
        default:
          break
      }
    }
    
    // Update all necessary section meshes
    sectionsToUpdate.forEach { section in
      if let chunkRenderer = chunkRenderers[section.chunk] {
        chunkRenderer.handleSectionUpdate(at: section.sectionY)
      }
    }
  }
  
  /// Creates renderers for all chunks that are renderable after the given update.
  func handleAddChunk(_ event: World.Event.AddChunk) {
    let affectedPositions = event.position.andNeighbours
    for position in affectedPositions {
      if canRenderChunk(at: position) && !chunkRenderers.keys.contains(position) {
        if let neighbour = world.chunk(at: position) {
          let neighbours = world.neighbours(ofChunkAt: position)
          
          let chunkRenderer = ChunkRenderer(
            for: neighbour,
            at: position,
            withNeighbours: neighbours,
            with: resources,
            world: world)
          chunkRenderers[position] = chunkRenderer
          log.debug("Created chunk renderer for chunk at \(position)")
        }
      }
    }
  }
  
  /// Removes all renderers made invalid by a given chunk removal.
  func handleRemoveChunk(_ event: World.Event.RemoveChunk) {
    let affectedChunks = event.position.andNeighbours
    for chunkPosition in affectedChunks {
      chunkRenderers.removeValue(forKey: chunkPosition)
    }
  }
  
  /// Handles a chunk lighting update.
  func handleLightingUpdate(_ event: World.Event.UpdateChunkLighting) {
    if let chunk = world.chunk(at: event.position) {
      if let renderer = chunkRenderers[event.position] {
        // TODO: only update sections affected by the lighting update
        renderer.invalidateMeshes()
      } else {
        let addChunkEvent = World.Event.AddChunk(
          position: event.position,
          chunk: chunk)
        handleAddChunk(addChunkEvent)
      }
    }
  }
  
  /// Returns whether a chunk is ready to be rendered or not.
  ///
  /// To be renderable, a chunk must be complete and so must its neighours.
  func canRenderChunk(at position: ChunkPosition) -> Bool {
    let chunkPositions = position.andNeighbours
    for chunkPosition in chunkPositions {
      if !world.chunkComplete(at: chunkPosition) {
        return false
      }
    }
    return true
  }
  
  /// Returns the sections that require re-meshing after the specified block update.
  func sectionsAffected(by blockUpdate: World.Event.SetBlock) -> [ChunkSectionPosition] {
    var affectedSections: [ChunkSectionPosition] = [blockUpdate.position.chunkSection]
    
    let updateRelativeToChunk = blockUpdate.position.relativeToChunk
    var affectedNeighbours: [CardinalDirection] = []
    if updateRelativeToChunk.z == 0 {
      affectedNeighbours.append(.north)
    } else if updateRelativeToChunk.z == 15 {
      affectedNeighbours.append(.south)
    }
    if updateRelativeToChunk.x == 15 {
      affectedNeighbours.append(.east)
    } else if updateRelativeToChunk.x == 0 {
      affectedNeighbours.append(.west)
    }
    
    for direction in affectedNeighbours {
      let neighbourChunk = blockUpdate.position.chunk.neighbour(inDirection: direction)
      let neighbourSection = ChunkSectionPosition(neighbourChunk, sectionY: updateRelativeToChunk.sectionIndex)
      affectedSections.append(neighbourSection)
    }
    
    // check whether sections above and below are also affected
    let updatedSection = blockUpdate.position.chunkSection
    
    let sectionHeight = Chunk.Section.height
    if updateRelativeToChunk.y % sectionHeight == sectionHeight - 1 && updateRelativeToChunk.y != Chunk.height - 1 {
      var section = updatedSection
      section.sectionY += 1
      affectedSections.append(section)
    } else if updateRelativeToChunk.y % sectionHeight == 0 && updateRelativeToChunk.y != 0 {
      var section = updatedSection
      section.sectionY -= 1
      affectedSections.append(section)
    }
    
    return affectedSections
  }
  
  /// Returns the positions of all valid chunk sections that neighbour the specific chunk section.
  func sectionsNeighbouring(sectionAt sectionPosition: ChunkSectionPosition) -> [ChunkSectionPosition] {
    var northNeighbour = sectionPosition
    northNeighbour.sectionZ -= 1
    var eastNeighbour = sectionPosition
    eastNeighbour.sectionX += 1
    var southNeighbour = sectionPosition
    southNeighbour.sectionZ += 1
    var westNeighbour = sectionPosition
    westNeighbour.sectionX -= 1
    var upNeighbour = sectionPosition
    upNeighbour.sectionY += 1
    var downNeighbour = sectionPosition
    downNeighbour.sectionY -= 1
    
    var neighbours = [northNeighbour, eastNeighbour, southNeighbour, westNeighbour]
    
    if upNeighbour.sectionY < Chunk.numSections {
      neighbours.append(upNeighbour)
    }
    if downNeighbour.sectionY >= 0 {
      neighbours.append(downNeighbour)
    }
    
    return neighbours
  }
  
  /// Returns a map from each cardinal direction to the given renderer's neighbour in that direction.
  func getNeighbourRenderers(of renderer: ChunkRenderer) -> [CardinalDirection: ChunkRenderer] {
    var neighbourRenderers: [CardinalDirection: ChunkRenderer] = [:]
    renderer.chunkPosition.allNeighbours.forEach { direction, neighbourPosition in
      if let neighbourRenderer = chunkRenderers[neighbourPosition] {
        neighbourRenderers[direction] = neighbourRenderer
      }
    }
    return neighbourRenderers
  }
  
  func createWorldUniforms(for camera: Camera) -> Uniforms {
    let worldToClipSpace = camera.getFrustum().worldToClip
    return Uniforms(transformation: worldToClipSpace)
  }
  
  func populateWorldUniformBuffer(_ buffer: inout MTLBuffer, with uniforms: inout Uniforms) {
    buffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
  }
  
  /// Decides whether to process a world event this frame.
  func shouldProcessWorldEvent(event: Event) -> Bool {
    switch event {
      case let blockUpdate as World.Event.SetBlock:
        // Postpone handling of the block update if it affects a frozen chunk section
        let affectedSections = sectionsAffected(by: blockUpdate)
        for section in affectedSections {
          if let renderer = chunkRenderers[section.chunk] {
            if renderer.sectionFrozen(at: section.sectionY) {
              return false
            }
          }
        }
        return true
      case let chunkUpdate as World.Event.UpdateChunk:
        // Postpone handling of the chunk update if any of the affected sections are are frozen
        if let renderer = chunkRenderers[chunkUpdate.position] {
          let neighbourRenderers = getNeighbourRenderers(of: renderer)
          for index in 0..<16 {
            if renderer.sectionFrozen(at: index - 1) || renderer.sectionFrozen(at: index + 1) {
              return false
            }
            for (_, renderer) in neighbourRenderers {
              if renderer.sectionFrozen(at: index) {
                return false
              }
            }
          }
        }
        return true
      case let chunkLightingUpdate as World.Event.UpdateChunkLighting:
        // Postpone handling of a lighting update if the chunk of any of its neighbours contain frozen sections
        let affectedChunks = chunkLightingUpdate.position.andNeighbours
        for chunkPosition in affectedChunks {
          if let renderer = chunkRenderers[chunkPosition] {
            if renderer.frozenSectionCount != 0 {
              return false
            }
          }
        }
        return true
      default:
        return true
    }
  }
  
  /// Also handles block updates.
  func getVisibleChunkRenderers(camera: Camera) -> [ChunkRenderer] {
    // Filter and handle world events
    let events = world.processBatch(filter: shouldProcessWorldEvent)
    handle(events)
    
    // Filter out chunks outside of render distance
    let playerChunkPosition = client.game.player.position.chunkPosition
    let chunkRenderersInRenderDistance = [ChunkRenderer](chunkRenderers.values).filter { renderer in
      let distance = max(
        abs(playerChunkPosition.chunkX - renderer.chunkPosition.chunkX),
        abs(playerChunkPosition.chunkZ - renderer.chunkPosition.chunkZ))
      return distance < client.config.renderDistance
    }
    
    // Sort chunks by distance from player
    let cameraPosition2d = SIMD2<Float>(camera.position.x, camera.position.z)
    var sortedChunkRenderers = chunkRenderersInRenderDistance.sorted {
      let point1 = SIMD2<Float>(
        Float($0.chunkPosition.chunkX) * Float(Chunk.width),
        Float($0.chunkPosition.chunkZ) * Float(Chunk.depth))
      let point2 = SIMD2<Float>(
        Float($1.chunkPosition.chunkX) * Float(Chunk.width),
        Float($1.chunkPosition.chunkZ) * Float(Chunk.depth))
      let distance1 = simd_distance_squared(cameraPosition2d, point1)
      let distance2 = simd_distance_squared(cameraPosition2d, point2)
      return distance2 > distance1
    }
    
    // Get visible chunks
    let visibleChunks = sortedChunkRenderers.map { $0.chunkPosition }.filter { chunkPosition in
      return camera.isChunkVisible(at: chunkPosition)
    }
    
    // Put visible chunks first
    sortedChunkRenderers.sort {
      return visibleChunks.contains($0.chunkPosition) && !visibleChunks.contains($1.chunkPosition)
    }
    
    // Remove prepared chunks from preparing chunks
    preparingChunks.forEach { chunkPosition in
      if let chunkRenderer = chunkRenderers[chunkPosition] {
        if chunkRenderer.hasCompletedInitialPrepare {
          log.trace("Removing prepared chunk at \(chunkPosition) from preparingChunks")
          preparingChunks.remove(chunkPosition)
        }
      }
    }
    
    let chunksToPrepare = sortedChunkRenderers.filter { chunkRenderer in
      return chunkRenderer.requiresPreparing
    }
    
    // Prepare chunks that require preparing and freeze any updates for them
    for chunkRenderer in chunksToPrepare {
      if preparingChunks.count == 3 {
        break
      }
      preparingChunks.insert(chunkRenderer.chunkPosition)
      chunkRenderer.prepareAsync()
    }
    
    // Get ChunkRenderers which are ready to be rendered
    let renderersToRender = sortedChunkRenderers.filter { chunkRenderer in
      return visibleChunks.contains(chunkRenderer.chunkPosition)
    }
    
    return renderersToRender
  }
  
  func updateAndGetUniformsBuffer(for camera: Camera) -> MTLBuffer {
    var worldUniforms = createWorldUniforms(for: camera)
    var buffer = worldUniformBuffers[worldUniformBufferIndex]
    worldUniformBufferIndex = (worldUniformBufferIndex + 1) % worldUniformBuffers.count
    populateWorldUniformBuffer(&buffer, with: &worldUniforms)
    return buffer
  }
  
  private static func createRenderEncoder(
    depthState: MTLDepthStencilState,
    commandBuffer: MTLCommandBuffer,
    renderPassDescriptor: MTLRenderPassDescriptor,
    pipelineState: MTLRenderPipelineState
  ) throws -> MTLRenderCommandEncoder {
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      throw RenderError.failedToCreateRenderEncoder(pipelineState.label ?? "pipeline")
    }
    
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.clockwise)
    renderEncoder.setCullMode(.back)
    
    return renderEncoder
  }
  
  func draw(
    device: MTLDevice,
    view: MTKView,
    renderCommandBuffer: MTLCommandBuffer,
    camera: Camera,
    commandQueue: MTLCommandQueue
  ) {
    // Update animated textures
    let updatedTextures = blockTexturePaletteAnimationState.update(tick: client.game.tickScheduler.tickNumber)
    stopwatch.startMeasurement("update texture")
    resources.blockTexturePalette.updateArrayTexture(arrayTexture: blockArrayTexture, device: device, animationState: blockTexturePaletteAnimationState, updatedTextures: updatedTextures, commandQueue: commandQueue)
    stopwatch.stopMeasurement("update texture")
    
    let uniformsBuffer = updateAndGetUniformsBuffer(for: camera)
    
    stopwatch.startMeasurement("get visible chunks")
    let renderersToRender = getVisibleChunkRenderers(camera: camera)
    stopwatch.stopMeasurement("get visible chunks")
    
    // Get the render pass descriptor as late as possible
    guard let renderPassDescriptor = view.currentRenderPassDescriptor
    else {
      log.warning("Failed to get current render pass descriptor")
      return
    }
    
    // Create descriptor
    let renderDescriptor = renderPassDescriptor
    renderDescriptor.colorAttachments[0].loadAction = .clear
    renderDescriptor.colorAttachments[0].storeAction = .store
    renderDescriptor.depthAttachment.storeAction = .store
      
    // Create encoder
    let renderEncoder: MTLRenderCommandEncoder
    do {
      renderEncoder = try Self.createRenderEncoder(
        depthState: depthState,
        commandBuffer: renderCommandBuffer,
        renderPassDescriptor: renderDescriptor,
        pipelineState: renderPipelineState)
    } catch {
      log.warning("Failed to create render command encoder; \(error)")
      return
    }
    
    // Encode render pass
    stopwatch.startMeasurement("encode")
    renderEncoder.setFragmentTexture(blockArrayTexture, index: 0)
    renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
      
    // Render opaque and transparent chunk geometry.
    renderersToRender.forEach { chunkRenderer in
      chunkRenderer.renderTransparentOpaque(
        renderEncoder: renderEncoder,
        with: device,
        and: camera,
        commandQueue: commandQueue)
    }
      
    // Render translucent chunk geometry afterwards (for correct blending).
    renderersToRender.forEach { chunkRenderer in
      chunkRenderer.renderTranslucent(
        renderEncoder: renderEncoder,
        with: device,
        and: camera,
        sortTranslucent: true,
        commandQueue: commandQueue)
    }
      
    renderEncoder.endEncoding()
    stopwatch.stopMeasurement("encode")
  }
}
