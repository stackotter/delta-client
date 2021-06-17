//
//  WorldRenderer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit
import simd

// TODO: Error enums should all have their own files

enum WorldRendererError: LocalizedError {
  case failedToCreateUniformBuffer
}

/// A renderer that renders a `World`
class WorldRenderer {
  var pipelineState: MTLRenderPipelineState
  var depthState: MTLDepthStencilState
  var blockArrayTexture: MTLTexture
  var blockPaletteManager: BlockPaletteManager
  
  var world: World
  var chunkRenderers: [ChunkPosition: ChunkRenderer] = [:]
  
  var preparingChunks: Set<ChunkPosition> = []
  
  init(world: World, blockPaletteManager: BlockPaletteManager, blockArrayTexture: MTLTexture) {
    log.info("Initialising WorldRenderer")
    
    // get metal device
    guard let metalDevice = MTLCreateSystemDefaultDevice() else {
      log.critical("No metal device found")
      fatalError("No metal device found")
    }
    
    // load shaders
    log.info("Loading chunk shaders")
    guard
      let defaultLibrary = metalDevice.makeDefaultLibrary(),
      let vertex = defaultLibrary.makeFunction(name: "chunkVertexShader"),
      let fragment = defaultLibrary.makeFunction(name: "chunkFragmentShader")
    else {
      log.critical("Failed to load chunk shaders")
      fatalError("Failed to load chunk shaders")
    }
    
    self.blockArrayTexture = blockArrayTexture
    self.blockPaletteManager = blockPaletteManager
    
    // create pipeline descriptor
    log.debug("Creating pipeline descriptor")
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "Triangle Pipeline"
    pipelineStateDescriptor.vertexFunction = vertex
    pipelineStateDescriptor.fragmentFunction = fragment
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    // create pipeline state
    log.debug("Creating pipeline state")
    do {
      pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      log.critical("Failed to create render pipeline state")
      fatalError("Failed to create render pipeline state")
    }
    
    // setup depth texture settings
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor) else {
      log.critical("Failed to create depth stencil state")
      fatalError("Failed to create depth stencil state")
    }
    self.depthState = depthState
    
    self.world = world
    log.info("Initialised WorldRenderer")
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
          chunkUpdate.data.presentSections.forEach { sectionIndex in
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
            with: blockPaletteManager)
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
  
  /**
   Returns whether a chunk is ready to be rendered or not.
   To be renderable a chunk must be complete and so must its neighours.
   */
  func canRenderChunk(at position: ChunkPosition) -> Bool {
    let chunkPositions = position.andNeighbours
    for chunkPosition in chunkPositions {
      if !world.chunkComplete(at: chunkPosition) {
        return false
      }
    }
    return true
  }
  
  /// Returns the sections that require re-meshing after the specified block update
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
  
  /// Returns the positions of all valid chunk sections that neighbour the specific chunk section
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
  
  /// Decides whether to process a world event this frame
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
          for index in chunkUpdate.data.presentSections {
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
  
  func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder, camera: Camera) {
    // get world to process the current batch of world events
    let events = world.processBatch(filter: shouldProcessWorldEvent(event:))
    
    // process the world events for WorldRenderer too
    handle(events)
    
    // sort chunks by distance from player
    let cameraPosition2d = simd_float2(camera.position.x, camera.position.z)
    var sortedChunkRenderers = [ChunkRenderer](chunkRenderers.values).sorted {
      let point1 = simd_float2(
        Float($0.chunkPosition.chunkX) * Float(Chunk.width),
        Float($0.chunkPosition.chunkZ) * Float(Chunk.depth))
      let point2 = simd_float2(
        Float($1.chunkPosition.chunkX) * Float(Chunk.width),
        Float($1.chunkPosition.chunkZ) * Float(Chunk.depth))
      let distance1 = simd_distance_squared(cameraPosition2d, point1)
      let distance2 = simd_distance_squared(cameraPosition2d, point2)
      return distance2 > distance1
    }
    
    // get visible chunks
    let visibleChunks = sortedChunkRenderers.map { $0.chunkPosition }.filter { chunkPosition in
      return camera.isChunkVisible(at: chunkPosition)
    }
    
    // put visible chunks first
    sortedChunkRenderers.sort {
      return visibleChunks.contains($0.chunkPosition) && !visibleChunks.contains($1.chunkPosition)
    }
    
    // remove prepared chunks from preparing chunks
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
    
    // prepare chunks that require preparing and freeze any updates for them
    for chunkRenderer in chunksToPrepare {
      if preparingChunks.count == 3 {
        break
      }
      preparingChunks.insert(chunkRenderer.chunkPosition)
      chunkRenderer.prepareAsync()
    }
    
    // get ChunkRenderers which are ready to be rendered
    let renderersToRender = sortedChunkRenderers.filter { chunkRenderer in
      return visibleChunks.contains(chunkRenderer.chunkPosition)
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
      log.error("Failed to create world uniform buffer")
      return
    }
    renderEncoder.setVertexBuffer(worldUniformBuffer, offset: 0, index: 1)
    
    // render chunks
    renderersToRender.forEach { chunkRenderer in
      chunkRenderer.render(to: renderEncoder, with: device, and: camera)
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
