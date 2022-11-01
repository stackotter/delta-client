import Foundation
import FirebladeMath

public struct Ray {
  public var origin: Vec3f
  public var direction: Vec3f

  init(origin: Vec3f, direction: Vec3f) {
    self.origin = origin
    self.direction = direction
  }

  init(from origin: Vec3f, pitch: Float, yaw: Float) {
    self.origin = origin
    direction = Vec3f(
      -Foundation.sin(yaw) * Foundation.cos(pitch),
      -Foundation.sin(pitch),
      Foundation.cos(yaw) * Foundation.cos(pitch)
    )
  }
}
