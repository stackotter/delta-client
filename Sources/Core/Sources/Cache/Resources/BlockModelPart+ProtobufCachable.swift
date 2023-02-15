extension BlockModelPart: ProtobufCachable {
  public init(from message: ProtobufBlockModelPart) throws {
    ambientOcclusion = message.ambientOcclusion

    if message.hasDisplayTransformsIndex {
      displayTransformsIndex = Int(message.displayTransformsIndex)
    }

    elements = []
    elements.reserveCapacity(message.elements.count)
    for element in message.elements {
      elements.append(try BlockModelElement(from: element))
    }
  }

  public func cached() -> ProtobufBlockModelPart {
    var message = ProtobufBlockModelPart()
    message.ambientOcclusion = ambientOcclusion

    if let displayTransformsIndex = displayTransformsIndex {
      message.displayTransformsIndex = Int32(displayTransformsIndex)
    }

    message.elements.reserveCapacity(elements.count)
    for element in elements {
      message.elements.append(element.cached())
    }

    return message
  }
}
