//
//  ChunkPreparer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation
import simd
import os

class ChunkPreparer {
  var server: Server
  
  var playerPosition: simd_float3!
  var frustum: Frustum!
  
  var thread: DispatchQueue = DispatchQueue(label: "chunkPreparerManagement")
  var preparingThread: DispatchQueue = DispatchQueue(label: "chunkPreparing", attributes: .concurrent)
  
  var isPreparingChunks: Bool = false
  
  var chunksToPrepare: [ChunkPosition] = []
  var chunksInFrustum: [ChunkPosition] = []
  var preparedChunks: [ChunkPosition] = []
  
  init(server: Server) {
    self.server = server
  }
  
  // Update Chunks
  
  func updateChunks() {
    if playerPosition != nil && frustum != nil {
      if let chunkPositions = server.world?.chunks.keys {
        let playerPosition2d = simd_float2(playerPosition.x, playerPosition.z)
        var sortedChunks = [ChunkPosition](chunkPositions).sorted(by: {
          let point1 = simd_float2(Float($0.chunkX), Float($0.chunkZ)) * 16
          let point2 = simd_float2(Float($1.chunkX), Float($1.chunkZ)) * 16
          let distance1 = simd_distance_squared(playerPosition2d, point1)
          let distance2 = simd_distance_squared(playerPosition2d, point2)
          return distance2 > distance1
        })
        
        let chunksInFrustum = sortedChunks.filter({ position in
          return frustum.approximatelyContains(AxisAlignedBoundingBox(forChunkAt: position))
        })
        
        sortedChunks.sort(by: {
          return !chunksInFrustum.contains($0) && chunksInFrustum.contains($1)
        })
        
        thread.sync {
          self.chunksToPrepare = sortedChunks.filter({ position in
            return !preparedChunks.contains(position)
          })
          self.chunksInFrustum = chunksInFrustum
        }
      }
    }
  }
  
  func updateChunkOrder(newPlayerPosition: simd_float3, newFrustum: Frustum) {
    self.frustum = newFrustum
    self.playerPosition = newPlayerPosition
    updateChunks()
  }
  
  func getVisibleChunks() -> [ChunkPosition] {
    thread.sync {
      return self.chunksInFrustum
    }
  }
  
  func prepareChunks() {
    if !isPreparingChunks {
      thread.async {
        if self.chunksToPrepare.count == 0 {
          return
        }
      }
      isPreparingChunks = true
      if let chunks = server.world?.chunks {
        preparingThread.async {
          while true {
            if let chunkPosition = self.getNextChunkToPrepare() {
              if let chunk = chunks[chunkPosition] {
                self.prepareChunk(chunk)
              }
            } else {
              break
            }
          }
        }
      }
      isPreparingChunks = false
    }
  }
  
  private func prepareChunk(_ chunk: Chunk) {
    if chunk.mesh.isEmpty {
      chunk.generateMesh()
    }
    thread.async {
      self.preparedChunks.append(chunk.position)
    }
  }
  
  func getNextChunkToPrepare() -> ChunkPosition? {
    thread.sync {
      if let position = chunksToPrepare.first {
        chunksToPrepare.removeFirst()
        return position
      }
      return nil
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
