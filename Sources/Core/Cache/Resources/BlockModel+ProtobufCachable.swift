extension BlockModel: ProtobufCachable {
  public init(from message: ProtobufBlockModel) throws {
    parts.reserveCapacity(message.parts.count)
    for part in message.parts {
      parts.append(try BlockModelPart(from: part))
    }
    
    cullingFaces.reserveCapacity(message.cullingFaces.count)
    for face in message.cullingFaces {
      cullingFaces.insert(try Direction(from: face))
    }
    
    cullableFaces.reserveCapacity(message.cullableFaces.count)
    for face in message.cullableFaces {
      cullableFaces.insert(try Direction(from: face))
    }
    
    nonCullableFaces.reserveCapacity(message.nonCullableFaces.count)
    for face in message.nonCullableFaces {
      nonCullableFaces.insert(try Direction(from: face))
    }
    
    textureType = try TextureType(from: message.textureType)
  }
  
  public func cached() -> ProtobufBlockModel {
    var message = ProtobufBlockModel()
    
    message.parts.reserveCapacity(parts.count)
    for part in parts {
      message.parts.append(part.cached())
    }
    
    message.cullingFaces.reserveCapacity(cullingFaces.count)
    for face in cullingFaces {
      message.cullingFaces.append(face.cached())
    }
    
    message.cullableFaces.reserveCapacity(cullableFaces.count)
    for face in cullableFaces {
      message.cullableFaces.append(face.cached())
    }
    
    message.nonCullableFaces.reserveCapacity(nonCullableFaces.count)
    for face in nonCullableFaces {
      message.nonCullableFaces.append(face.cached())
    }
    
    message.textureType = textureType.cached()
    
    return message
  }
}
