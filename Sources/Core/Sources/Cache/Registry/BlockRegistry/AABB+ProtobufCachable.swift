extension AxisAlignedBoundingBox: ProtobufCachable {
  public init(from message: ProtobufAABB) {
    position = SIMD3<Double>(SIMD3<Float>(from: message.position))
    size = SIMD3<Double>(SIMD3<Float>(from: message.size))
  }
  
  public func cached() -> ProtobufAABB {
    var message = ProtobufAABB()
    message.position = SIMD3<Float>(position).cached()
    message.size = SIMD3<Float>(size).cached()
    return message
  }
}
