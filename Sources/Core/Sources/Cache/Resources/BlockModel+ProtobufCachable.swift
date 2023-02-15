extension BlockModel: ProtobufCachable {
  public init(from message: ProtobufBlockModel) throws {
    parts = []
    parts.reserveCapacity(message.parts.count)
    for part in message.parts {
      parts.append(try BlockModelPart(from: part))
    }

    cullingFaces = DirectionSet(rawValue: UInt8(message.cullingFaces))
    cullableFaces = DirectionSet(rawValue: UInt8(message.cullableFaces))
    nonCullableFaces = DirectionSet(rawValue: UInt8(message.nonCullableFaces))

    textureType = try TextureType(from: message.textureType)
  }

  public func cached() -> ProtobufBlockModel {
    var message = ProtobufBlockModel()

    message.parts.reserveCapacity(parts.count)
    for part in parts {
      message.parts.append(part.cached())
    }

    message.cullingFaces = Int32(cullingFaces.rawValue)
    message.cullableFaces = Int32(cullableFaces.rawValue)
    message.nonCullableFaces = Int32(nonCullableFaces.rawValue)
    message.textureType = textureType.cached()

    return message
  }
}
