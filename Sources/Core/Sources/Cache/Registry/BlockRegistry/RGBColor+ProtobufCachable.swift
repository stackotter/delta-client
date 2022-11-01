import FirebladeMath

extension RGBColor: ProtobufCachable {
  public init(from message: ProtobufBlockTintRGBColor) {
    vector = Vec3i(
      Int(message.r),
      Int(message.g),
      Int(message.b)
    )
  }

  public func cached() -> ProtobufBlockTintRGBColor {
    var message = ProtobufBlockTintRGBColor()
    message.r = Int32(vector.x)
    message.g = Int32(vector.y)
    message.b = Int32(vector.z)
    return message
  }
}
