import FirebladeMath

extension BlockModelFace: ProtobufCachable {
  public init(from message: ProtobufBlockModelFace) throws {
    direction = try Direction(from: message.direction)
    actualDirection = try Direction(from: message.actualDirection)

    let cachedUVs = message.uvs
    uvs = [
      Vec2f(cachedUVs[0], cachedUVs[1]),
      Vec2f(cachedUVs[2], cachedUVs[3]),
      Vec2f(cachedUVs[4], cachedUVs[5]),
      Vec2f(cachedUVs[6], cachedUVs[7])
    ]

    texture = Int(message.texture)

    if message.hasCullface {
      cullface = try Direction(from: message.cullface)
    }

    isTinted = message.isTinted
  }

  public func cached() -> ProtobufBlockModelFace {
    var message = ProtobufBlockModelFace()
    message.direction = direction.cached()
    message.actualDirection = actualDirection.cached()

    message.uvs = [
      uvs[0].x, uvs[0].y,
      uvs[1].x, uvs[1].y,
      uvs[2].x, uvs[2].y,
      uvs[3].x, uvs[3].y
    ]

    message.texture = Int32(texture)

    if let cullface = cullface {
      message.cullface = cullface.cached()
    }

    message.isTinted = isTinted

    return message
  }
}
