import Foundation
import simd

public struct Ray {
  public var origin: SIMD3<Float>
  public var direction: SIMD3<Float>

  init(origin: SIMD3<Float>, direction: SIMD3<Float>) {
    self.origin = origin
    self.direction = direction
  }

  init(from origin: SIMD3<Float>, pitch: Float, yaw: Float) {
    self.origin = origin
    direction = [-sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)]
  }
}
