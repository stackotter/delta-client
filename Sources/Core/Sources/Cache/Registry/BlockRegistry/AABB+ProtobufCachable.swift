extension AxisAlignedBoundingBox: ProtobufCachable {
  public init(from message: ProtobufAABB) {
    position = SIMD3<Float>(from: message.position)
    size = SIMD3<Float>(from: message.size)
  }
  
  public func cached() -> ProtobufAABB {
    var message = ProtobufAABB()
    message.position = position.cached()
    message.size = size.cached()
    return message
  }
}
