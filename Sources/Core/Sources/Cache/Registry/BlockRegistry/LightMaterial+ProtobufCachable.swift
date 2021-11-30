extension Block.LightMaterial: ProtobufCachable {
  public init(from message: ProtobufBlockLightMaterial) {
    isTranslucent = message.isTranslucent
    opacity = Int(message.opacity)
    luminance = Int(message.luminance)
    isConditionallyTransparent = message.isConditionallyTransparent
  }
  
  public func cached() -> ProtobufBlockLightMaterial {
    var message = ProtobufBlockLightMaterial()
    message.isTranslucent = isTranslucent
    message.opacity = Int32(opacity)
    message.luminance = Int32(luminance)
    message.isConditionallyTransparent = isConditionallyTransparent
    return message
  }
}

