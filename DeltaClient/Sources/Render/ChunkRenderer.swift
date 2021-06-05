//
//  ChunkRenderer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation
import MetalKit

class ChunkRenderer {
  var position: ChunkPosition
  var chunk: Chunk
  
  var neighbourChunks: [CardinalDirection: Chunk] = [:]
  
  var blockPaletteManager: BlockPaletteManager
  var mesh: ChunkMesh?
  
  // TODO: remove need to pass block palette manager
  init(for chunk: Chunk, at position: ChunkPosition, with blockPaletteManager: BlockPaletteManager) {
    self.position = position
    self.chunk = chunk
    self.blockPaletteManager = blockPaletteManager
  }
  
  func handle(_ event: World.Event.SetBlock) {
    // check if update is relevant
    if event.position.chunkPosition != position {
      Logger.warn("Invalid SetBlock event sent to ChunkRenderer")
      return
    }
    
    // update mesh
    let relativePosition = event.position.relativeToChunk
    mesh?.replaceBlock(at: relativePosition.blockIndex, with: event.newState)
  }
  
  func handleNeighbour(_ event: World.Event.SetBlock, direction: CardinalDirection) {
    // calculate affected block's position and discard event if change is irrelevant
    let positionInNeighbour = event.position.relativeToChunk
    var affectedPosition = positionInNeighbour
    switch direction {
      case .north:
        if positionInNeighbour.z != 15 {
          Logger.debug("Discarding neighbouring change to the \(direction)")
          return
        }
        affectedPosition.z = 0
      case .east:
        if positionInNeighbour.x != 0 {
          Logger.debug("Discarding neighbouring change to the \(direction)")
          return
        }
        affectedPosition.x = 15
      case .south:
        if positionInNeighbour.z != 0 {
          Logger.debug("Discarding neighbouring change to the \(direction)")
          return
        }
        affectedPosition.z = 15
      case .west:
        if positionInNeighbour.x != 15 {
          Logger.debug("Discarding neighbouring change to the \(direction)")
          return
        }
        affectedPosition.x = 0
    }
    
    // update mesh
    let blockIndex = affectedPosition.blockIndex
    let blockState = chunk.getBlock(at: blockIndex)
    mesh?.replaceBlock(at: blockIndex, with: blockState, shouldUpdateNeighbours: false)
  }
  
  func setNeighbour(to neighbour: Chunk, direction: CardinalDirection) {
    neighbourChunks[direction] = neighbour
  }
  
  func prepare() {
    let mesh = ChunkMesh(
      blockPaletteManager: blockPaletteManager,
      chunk: chunk,
      position: position,
      neighbourChunks: neighbourChunks)
    mesh.prepare()
    self.mesh = mesh
  }
  
  func invalidateMesh() {
    mesh = nil
  }
  
  func isReadyToRender() -> Bool {
    return neighbourChunks.count == 4 && mesh != nil
  }
  
  func isReadyToPrepare() -> Bool {
    return neighbourChunks.count == 4 && mesh == nil
  }
  
  func render(to encoder: MTLRenderCommandEncoder, with device: MTLDevice) {
    if let buffers = try? mesh?.createBuffers(device: device) {
      encoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0) // set vertices
      encoder.setVertexBuffer(buffers.uniformBuffer, offset: 0, index: 2) // set chunk specific uniforms
      encoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: buffers.indexBuffer.length / 4,
        indexType: .uint32,
        indexBuffer: buffers.indexBuffer,
        indexBufferOffset: 0)
    } else {
      Logger.error("failed to prepare buffers for chunk at \(position.chunkX),\(position.chunkZ)")
    }
  }
}
