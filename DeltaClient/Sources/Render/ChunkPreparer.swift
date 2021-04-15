//
//  ChunkPreparer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation
import simd

class ChunkPreparer {
  var server: Server
  var chunkOrder: [ChunkPosition] = []
  var chunksInFrustum: [ChunkPosition] = []
  var preparedChunks: [ChunkPosition] = []
  var thread: DispatchQueue = DispatchQueue(label: "chunkPreparerManagement")
  var preparingThread: DispatchQueue = DispatchQueue(label: "chunkPreparing", attributes: .concurrent)
  
  var playerPosition: simd_float3!
  var frustum: Frustum!
  
  init(server: Server) {
    self.server = server
  }
  
  func updateChunkOrder(newPlayerPosition: simd_float3, newFrustum: Frustum) {
    self.frustum = newFrustum
    self.playerPosition = newPlayerPosition
    if let chunkPositions = server.currentWorld?.chunks.keys {
      let playerPosition2d = simd_float2(playerPosition.x, playerPosition.z)
      let chunkOrder = [ChunkPosition](chunkPositions).sorted(by: {
        let point1 = simd_float2(Float($0.chunkX), Float($0.chunkZ))
        let point2 = simd_float2(Float($1.chunkX), Float($1.chunkZ))
        let distance1 = simd_distance_squared(playerPosition2d, point1)
        let distance2 = simd_distance_squared(playerPosition2d, point2)
        return distance2 > distance1
      })
      
      let chunksInFrustum = chunkOrder.filter({ position in
        return frustum.approximatelyContains(AxisAlignedBoundingBox(forChunkAt: position))
      })
      
      thread.sync {
        self.chunkOrder = chunkOrder
        self.chunksInFrustum = chunksInFrustum
      }
    }
  }
  
  func getVisibleChunks() -> [ChunkPosition] {
    thread.sync {
      return self.chunksInFrustum
    }
  }
  
  func prepareChunks() {
    let visibleChunks = getVisibleChunks()
    if let chunks = server.currentWorld?.chunks {
      for chunkPosition in visibleChunks {
        if let chunk = chunks[chunkPosition] {
          prepareChunk(chunk)
        }
      }
    }
  }
  
  func prepareChunk(_ chunk: Chunk) {
    preparingThread.async {
      chunk.generateMesh()
      self.thread.async {
        self.preparedChunks.append(chunk.position)
      }
    }
  }
  
  func getChunksToRender() -> [ChunkPosition] {
    thread.sync {
      return chunksInFrustum.filter({ chunkPosition in
        return preparedChunks.contains(chunkPosition)
      })
    }
  }
}
