//
//  ChunkPreparer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/4/21.
//

import Foundation
import simd


class ChunkPreparer {
  var world: World
  var camera: Camera
  
  var thread = DispatchQueue(label: "chunkPreparerManagement")
  var preparingThread = DispatchQueue(label: "chunkPreparing")
  
  var isPreparingChunks = false
  
  var chunksToPrepare: [ChunkPosition] = []
  var chunksInFrustum: [ChunkPosition] = []
  var preparedChunks: [ChunkPosition] = []
  
  init(world: World, camera: Camera) {
    self.world = world
    self.camera = camera
  }
  
  // Update Chunks
  
  func updateChunks() {
    // sort chunks by distance from camera
    let cameraPosition2d = simd_float2(camera.position.x, camera.position.z)
    let chunkPositions = world.chunks.keys
    var sortedChunks = [ChunkPosition](chunkPositions).sorted(by: {
      let point1 = simd_float2(Float($0.chunkX) * Float(Chunk.WIDTH), Float($0.chunkZ) * Float(Chunk.DEPTH))
      let point2 = simd_float2(Float($1.chunkX) * Float(Chunk.WIDTH), Float($1.chunkZ) * Float(Chunk.DEPTH))
      let distance1 = simd_distance_squared(cameraPosition2d, point1)
      let distance2 = simd_distance_squared(cameraPosition2d, point2)
      return distance2 > distance1
    })
    
    // get chunks that are approximately visible (there are some false positives)
    let frustum = camera.getFrustum()
    let chunksInFrustum = sortedChunks.filter({ position in
      return frustum.approximatelyContains(AxisAlignedBoundingBox(forChunkAt: position))
    })
    
    // prepare chunks in frustum first
    sortedChunks.sort(by: {
      return !chunksInFrustum.contains($0) && chunksInFrustum.contains($1)
    })
    
    // update chunks
    thread.sync {
      self.chunksToPrepare = sortedChunks.filter({ position in
        return !preparedChunks.contains(position)
      })
      self.chunksInFrustum = chunksInFrustum
    }
  }
  
  func setCamera(_ camera: Camera) {
    self.camera = Camera()
    updateChunks()
  }
  
  func getVisibleChunks() -> [ChunkPosition] {
    thread.sync {
      return self.chunksInFrustum
    }
  }
  
  func prepareChunks() {
    if !isPreparingChunks {
      // TODO: use a lock
      isPreparingChunks = true
      if self.getNumChunksLeftToPrepare() == 0 {
        isPreparingChunks = false
        return
      }
      preparingThread.async {
        while true {
          self.prepareNextChunk()
          if self.getNumChunksLeftToPrepare() == 0 {
            break
          }
        }
      }
      isPreparingChunks = false
    }
  }
  
  private func getNumChunksLeftToPrepare() -> Int {
    thread.sync {
      return self.chunksToPrepare.count
    }
  }
  
  private func prepareNextChunk() {
    if let chunkPosition = self.getNextChunkToPrepare() {
      if world.getIsChunkReady(chunkPosition), let chunk = world.chunks[chunkPosition] {
        self.prepareChunk(chunk)
      }
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
