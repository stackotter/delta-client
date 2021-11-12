/// A component storing an entity's rotation in radians.
public struct EntityRotation {
  /// Pitch in radians.
  public var pitch: Float
  /// Yaw in radians.
  public var yaw: Float
  
  /// Creates an entity's rotation.
  public init(pitch: Float, yaw: Float) {
    self.pitch = pitch
    self.yaw = yaw
  }
  
  /// Convert rotations from 1/265ths to radians.
  public init(pitch: UInt8, yaw: UInt8) {
    self.pitch = .pi * Float(pitch) / 128
    self.yaw = .pi * Float(pitch) / 128
  }
}
