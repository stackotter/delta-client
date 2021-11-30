extension Block.Tint: ProtobufCachable {
  public init(from message: ProtobufBlockTint) throws {
    if message.hasComputedTint {
      self = .computed(try Block.ComputedTintType(from: message.computedTint))
    } else if message.hasHardcodedTint {
      self = .hardcoded(RGBColor(from: message.hardcodedTint))
    } else {
      throw BlockRegistryError.invalidBlockTint
    }
  }
  
  public func cached() -> ProtobufBlockTint {
    var message = ProtobufBlockTint()
    switch self {
      case .computed(let computedType):
        message.computedTint = computedType.cached()
      case .hardcoded(let color):
        message.hardcodedTint = color.cached()
    }
    return message
  }
}
