//
//  BlockModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import simd

struct BlockModelElement {
  var modelMatrix: simd_float4x4
  var faces: [FaceDirection: BlockModelElementFace]
  
  init(modelMatrix: simd_float4x4, faces: [FaceDirection: BlockModelElementFace]) {
    self.modelMatrix = modelMatrix
    self.faces = faces
  }
  
  init(fromCache cache: CacheBlockModelElement) {
    modelMatrix = matrix_float4x4.fromData(cache.modelMatrix)
    faces = [:]
    for (cacheDirectionRaw, cacheFace) in cache.faces {
      let direction = FaceDirection(rawValue: Int(cacheDirectionRaw))!
      let face = BlockModelElementFace(fromCache: cacheFace)
      faces[direction] = face
    }
  }
  
  func toCache() -> CacheBlockModelElement {
    let cacheModelMatrix = modelMatrix.toData()
    var cacheFaces: [Int64: CacheBlockModelElementFace] = [:]
    for (direction, face) in faces {
      let cacheDirection = direction.toCache()
      let cacheFace = face.toCache()
      let cacheDirectionRaw = Int64(cacheDirection.rawValue)
      cacheFaces[cacheDirectionRaw] = cacheFace
    }
    
    var cacheElement = CacheBlockModelElement()
    cacheElement.modelMatrix = cacheModelMatrix
    cacheElement.faces = cacheFaces
    
    return cacheElement
  }
}

extension matrix_float4x4 {
  func toData() -> Data {
    var mutableSelf = self
    let data = Data(bytes: &mutableSelf, count: MemoryLayout<matrix_float4x4>.size)
    return data
  }
  
  static func fromData(_ data: Data) -> matrix_float4x4 {
    var matrix = matrix_float4x4()
    _ = withUnsafeMutableBytes(of: &matrix.columns) {
      data.copyBytes(to: $0)
    }
    return matrix
  }
}
