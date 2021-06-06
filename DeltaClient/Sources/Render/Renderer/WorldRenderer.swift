//
//  WorldRenderer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import simd

enum WorldRendererError: LocalizedError {
  case failedToCreateUniformBuffer
}

class WorldRenderer {
  var pipelineState: MTLRenderPipelineState
  var depthState: MTLDepthStencilState
  var blockArrayTexture: MTLTexture
  var blockPaletteManager: BlockPaletteManager
  
  var world: World
  var chunkRenderers: [ChunkPosition: ChunkRenderer] = [:]
  
  var chunkPreparationThread = DispatchQueue(
    label: "WorldRenderer.chunkPreparationThread",
    attributes: .concurrent)
  
  var frozenChunks = Set<ChunkPosition>()
  var frozenChunkNeighbourBlockUpdates: [ChunkPosition: [(CardinalDirection, World.Event.SetBlock)]] = [:]
  
  init(world: World, blockPaletteManager: BlockPaletteManager, blockArrayTexture: MTLTexture) {
    Logger.info("Initialising WorldRenderer")
    
    // get metal device
    guard let metalDevice = MTLCreateSystemDefaultDevice() else {
      Logger.error("No metal device found")
      fatalError("No metal device found")
    }
    
    // load shaders
    Logger.info("Loading shaders")
    guard
      let defaultLibrary = metalDevice.makeDefaultLibrary(),
      let vertex = defaultLibrary.makeFunction(name: "chunkVertexShader"),
      let fragment = defaultLibrary.makeFunction(name: "chunkFragmentShader")
    else {
      Logger.error("Failed to load chunk shaders")
      fatalError("Failed to load chunk shaders")
    }
    
    self.blockArrayTexture = blockArrayTexture
    self.blockPaletteManager = blockPaletteManager
    
    // create pipeline descriptor
    Logger.info("Creating pipeline descriptor")
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Triangle Pipeline"
    pipelineStateDescriptor.vertexFunction = vertex
    pipelineStateDescriptor.fragmentFunction = fragment
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    // create pipeline state
    Logger.info("Creating pipeline state")
    do {
      pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      Logger.error("Failed to create render pipeline state")
      fatalError("Failed to create render pipeline state")
    }
    
    // setup depth texture settings
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor) else {
      Logger.error("Failed to create depth stencil state")
      fatalError("Failed to create depth stencil state")
    }
    self.depthState = depthState
    
    self.world = world
    Logger.info("Initialised WorldRenderer")
  }
  
  func handle(_ events: [Event]) {
    events.forEach { event in
      switch event {
        case let event as World.Event.AddChunk:
          handle(event)
        case let event as World.Event.RemoveChunk:
          handle(event)
        case let event as World.Event.SetBlock:
          handle(event)
        default:
          break
      }
    }
    
    // send block changes to neighbouring chunks of the block change
    // this must be done after the block changes have all been processed in their chunks
    events.forEach { event in
      switch event {
        case let event as World.Event.SetBlock:
          handleNeighbours(event)
        default:
          break
      }
    }
  }
  
  func handle(_ event: World.Event.AddChunk) {
    // create renderer
    let position = event.position
    let renderer = ChunkRenderer(for: event.chunk, at: position, with: blockPaletteManager)
    
    // set chunk's neighbours
    for (direction) in CardinalDirection.allDirections {
      let neighbourPosition = position.neighbour(inDirection: direction)
      if let neighbourRenderer = chunkRenderers[neighbourPosition] {
        renderer.setNeighbour(to: neighbourRenderer.chunk, direction: direction)
        neighbourRenderer.setNeighbour(to: renderer.chunk, direction: direction.opposite)
      }
    }
    
    // add chunk renderer
    chunkRenderers[position] = renderer
  }
  
  func handle(_ event: World.Event.RemoveChunk) {
    if let renderer = chunkRenderers.removeValue(forKey: event.position) {
      let neighbourRenderers = getNeighbourRenderers(of: renderer)
      for (direction, neighbourRenderer) in neighbourRenderers {
        neighbourRenderer.invalidateMesh()
        neighbourRenderer.neighbourChunks.removeValue(forKey: direction.opposite)
      }
    }
  }
  
  func handle(_ event: World.Event.SetBlock) {
    if let renderer = chunkRenderers[event.position.chunkPosition] {
      renderer.handleBlockChange(event)
    }
  }
  
  func handleNeighbours(_ event: World.Event.SetBlock) {
    if let renderer = chunkRenderers[event.position.chunkPosition] {
      for (direction, neighbourRenderer) in getNeighbourRenderers(of: renderer) {
        if frozenChunks.contains(neighbourRenderer.position) {
          // we just save the event and catch up the frozen chunk once it is unfrozen
          var updates = frozenChunkNeighbourBlockUpdates[neighbourRenderer.position] ?? []
          updates.append((direction.opposite, event))
          frozenChunkNeighbourBlockUpdates[neighbourRenderer.position] = updates
        } else {
          neighbourRenderer.handleNeighbourBlockChange(event, direction: direction)
        }
      }
    }
  }
  
  func getNeighbourRenderers(of renderer: ChunkRenderer) -> [CardinalDirection: ChunkRenderer] {
    var neighbourRenderers: [CardinalDirection: ChunkRenderer] = [:]
    renderer.neighbourChunks.forEach { direction, _ in
      let neighbourPosition = renderer.position.neighbour(inDirection: direction)
      if let neighbourRenderer = chunkRenderers[neighbourPosition] {
        neighbourRenderers[direction] = neighbourRenderer
      }
    }
    return neighbourRenderers
  }
  
  func createWorldUniforms(for camera: Camera) -> Uniforms {
    let worldToClipSpace = camera.getWorldToClipMatrix()
    return Uniforms(transformation: worldToClipSpace)
  }
  
  func createWorldUniformBuffer(from uniforms: Uniforms, for device: MTLDevice) throws -> MTLBuffer! {
    var mutableUniforms = uniforms
    
    guard
      let uniformBuffer = device.makeBuffer(
        bytes: &mutableUniforms,
        length: MemoryLayout<Uniforms>.stride,
        options: [])
    else {
      throw WorldRendererError.failedToCreateUniformBuffer
    }
    
    uniformBuffer.label = "worldUniformBuffer"
    return uniformBuffer
  }
  
  func freezeChunk(at chunkPosition: ChunkPosition) {
    frozenChunks.insert(chunkPosition)
  }
  
  func unfreezeChunk(at chunkPosition: ChunkPosition) {
    frozenChunks.remove(chunkPosition)
    if
      let chunkRenderer = chunkRenderers[chunkPosition],
      let neighbourUpdates = frozenChunkNeighbourBlockUpdates[chunkPosition]
    {
      neighbourUpdates.forEach { neighbourEvent in
        let (direction, event) = neighbourEvent
        chunkRenderer.handleNeighbourBlockChange(event, direction: direction)
      }
    }
  }
  
  /// Decides whether to process a world event this frame
  func shouldProcessWorldEvent(event: Event) -> Bool {
    switch event {
      case let event as World.Event.SetBlock:
        let isChunkFrozen = frozenChunks.contains(event.position.chunkPosition)
        return !isChunkFrozen
      default:
        return true
    }
  }
  
  func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder, camera: Camera) {
    // get world to process the current batch of world events
    let events = world.processBatch(filter: shouldProcessWorldEvent(event:))
    
    // process the world events for WorldRenderer too
    handle(events)
    
    // unfreeze renderers that have finished preparing
    let frozenRenderers = frozenChunks.map { chunkPosition in
      return chunkRenderers[chunkPosition]
    }
    
    frozenRenderers.forEach { chunkRenderer in
      if let chunkRenderer = chunkRenderer,
         chunkRenderer.isReadyToRender() {
        Logger.debug("Unfreezing chunk at \(chunkRenderer.position)")
        unfreezeChunk(at: chunkRenderer.position)
      }
    }
    
    // sort chunks by distance from player
    let cameraPosition2d = simd_float2(camera.position.x, camera.position.z)
    var sortedChunkRenderers = [ChunkRenderer](chunkRenderers.values).sorted {
      let point1 = simd_float2(
        Float($0.position.chunkX) * Float(Chunk.width),
        Float($0.position.chunkZ) * Float(Chunk.depth))
      let point2 = simd_float2(
        Float($1.position.chunkX) * Float(Chunk.width),
        Float($1.position.chunkZ) * Float(Chunk.depth))
      let distance1 = simd_distance_squared(cameraPosition2d, point1)
      let distance2 = simd_distance_squared(cameraPosition2d, point2)
      return distance2 > distance1
    }
    
    // get visible chunks
    let visibleChunks = sortedChunkRenderers.map { $0.position }.filter { chunkPosition in
      return camera.isChunkVisible(at: chunkPosition)
    }
    
    // put visible chunks first
    sortedChunkRenderers.sort {
      return visibleChunks.contains($0.position) && !visibleChunks.contains($1.position)
    }
    
    // get list of chunks still to be prepared
    let renderersToPrepare = sortedChunkRenderers.filter { chunkRenderer in
      return chunkRenderer.isReadyToPrepare() &&
        !frozenChunks.contains(chunkRenderer.position)
    }
    
    // prepare chunks that require preparing and freeze any updates for them
    for chunkRenderer in renderersToPrepare {
      if frozenChunks.count == 3 {
        break
      }
      freezeChunk(at: chunkRenderer.position)
      chunkPreparationThread.async {
        Logger.debug("Preparing chunk at \(chunkRenderer.position)")
        chunkRenderer.prepare()
        Logger.debug("Prepared chunk at \(chunkRenderer.position)")
      }
    }
    
    // get ChunkRenderers which are ready to be rendered
    let renderersToRender = sortedChunkRenderers.filter { chunkRenderer in
      return visibleChunks.contains(chunkRenderer.position) &&
        chunkRenderer.isReadyToRender() &&
        !frozenChunks.contains(chunkRenderer.position)
    }
    
    // encode render pipeline
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.clockwise)
    renderEncoder.setCullMode(.back)
    
    renderEncoder.setFragmentTexture(blockArrayTexture, index: 0)
    
    if Constants.renderMode == .wireframe {
      renderEncoder.setTriangleFillMode(.lines)
      renderEncoder.setCullMode(.none)
    }
    
    // set uniforms
    let worldUniforms = createWorldUniforms(for: camera)
    guard let worldUniformBuffer = try? createWorldUniformBuffer(from: worldUniforms, for: device) else {
      Logger.error("Failed to create world uniform buffer")
      return
    }
    renderEncoder.setVertexBuffer(worldUniformBuffer, offset: 0, index: 1)
    
    // render chunks
    renderersToRender.forEach { chunkRenderer in
      chunkRenderer.render(to: renderEncoder, with: device)
    }
  }
}

extension WorldRenderer {
  enum RenderMode {
    case normal
    case wireframe
  }
  
  enum Constants {
    static let renderMode = RenderMode.normal
  }
}
