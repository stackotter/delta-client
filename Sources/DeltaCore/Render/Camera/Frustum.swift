//
//  Frustum.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/4/21.
//

import Foundation
import simd

// method from: http://web.archive.org/web/20120531231005/http://crazyjoke.free.fr/doc/3D/plane%20extraction.pdf
struct Frustum {
  var left: simd_float4
  var right: simd_float4
  var top: simd_float4
  var bottom: simd_float4
  var near: simd_float4
  var far: simd_float4
  
  init(worldToClip: matrix_float4x4) {
    left = worldToClip.columns.3 + worldToClip.columns.0
    right = worldToClip.columns.3 - worldToClip.columns.0
    bottom = worldToClip.columns.3 + worldToClip.columns.1
    top = worldToClip.columns.3 - worldToClip.columns.1
    near = worldToClip.columns.2
    far = worldToClip.columns.3 - worldToClip.columns.2
  }
  
  func approximatelyContains(_ boundingBox: AxisAlignedBoundingBox) -> Bool {
    let vertices = boundingBox.getVertices()
    
    var homogenousVertices: [simd_float4] = []
    for vertex in vertices {
      let homogenousVertex = simd_float4(vertex, 1)
      homogenousVertices.append(homogenousVertex)
    }
    
    let planeVectors = [left, right, near, bottom, top]
    
    for planeVector in planeVectors {
      var boundingBoxLiesOutside = true
      for vertex in homogenousVertices {
        if dot(vertex, planeVector) > 0 {
          boundingBoxLiesOutside = false
          break
        }
      }
      if boundingBoxLiesOutside {
        return false
      }
    }
    
    // the bounding box does not lie completely outside any of the frustum planes
    // although it may still be outside the frustum (hence approximate)
    return true
  }
}
