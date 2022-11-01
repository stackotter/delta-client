import FirebladeMath

extension AxisAlignedBoundingBox: ProtobufCachable {
  public init(from message: ProtobufAABB) {
    position = Vec3d(Vec3f(from: message.position))
    size = Vec3d(Vec3f(from: message.size))
  }

  public func cached() -> ProtobufAABB {
    var message = ProtobufAABB()
    message.position = Vec3f(position).cached()
    message.size = Vec3f(size).cached()
    return message
  }
}
