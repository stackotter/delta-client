extension SIMD3: ProtobufCachable where Scalar == Float {
  public init(from message: ProtobufVec3f) {
    self.init(
      x: message.x,
      y: message.y,
      z: message.z)
  }
  
  public func cached() -> ProtobufVec3f {
    var message = ProtobufVec3f()
    message.x = x
    message.y = y
    message.z = z
    return message
  }
}
