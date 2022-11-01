import Foundation
import FirebladeMath

// method from: http://web.archive.org/web/20120531231005/http://crazyjoke.free.fr/doc/3D/plane%20extraction.pdf
public struct Frustum {
  public var worldToClip: Mat4x4f
  public var left: Vec4d
  public var right: Vec4d
  public var top: Vec4d
  public var bottom: Vec4d
  public var near: Vec4d
  public var far: Vec4d

  public init(worldToClip: Mat4x4f) {
    self.worldToClip = worldToClip

    let columns = worldToClip.columns
    left = Vec4d(columns.3 + columns.0)
    right = Vec4d(columns.3 - columns.0)
    bottom = Vec4d(columns.3 + columns.1)
    top = Vec4d(columns.3 - columns.1)
    near = Vec4d(columns.2)
    far = Vec4d(columns.3 - columns.2)
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
