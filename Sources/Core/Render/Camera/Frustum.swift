import Foundation
import simd

// method from: http://web.archive.org/web/20120531231005/http://crazyjoke.free.fr/doc/3D/plane%20extraction.pdf
public struct Frustum {
  public var worldToClip: matrix_float4x4
  public var left: SIMD4<Double>
  public var right: SIMD4<Double>
  public var top: SIMD4<Double>
  public var bottom: SIMD4<Double>
  public var near: SIMD4<Double>
  public var far: SIMD4<Double>
  
  public init(worldToClip: matrix_float4x4) {
    self.worldToClip = worldToClip
    left = SIMD4<Double>(worldToClip.columns.3 + worldToClip.columns.0)
    right = SIMD4<Double>(worldToClip.columns.3 - worldToClip.columns.0)
    bottom = SIMD4<Double>(worldToClip.columns.3 + worldToClip.columns.1)
    top = SIMD4<Double>(worldToClip.columns.3 - worldToClip.columns.1)
    near = SIMD4<Double>(worldToClip.columns.2)
    far = SIMD4<Double>(worldToClip.columns.3 - worldToClip.columns.2)
  }
  
  public func approximatelyContains(_ boundingBox: AxisAlignedBoundingBox) -> Bool {
    let homogenousVertices = boundingBox.getHomogenousVertices()
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
