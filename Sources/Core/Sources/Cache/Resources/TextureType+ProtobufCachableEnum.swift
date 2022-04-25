extension TextureType: ProtobufCachableEnum {
  public init(from protobufEnum: ProtobufTextureType) throws {
    switch protobufEnum {
      case .opaque:
        self = .opaque
      case .transparent:
        self = .transparent
      case .translucent:
        self = .translucent
      case .UNRECOGNIZED:
        throw BlockModelPaletteError.invalidTextureType
    }
  }
  
  public func cached() -> ProtobufTextureType {
    switch self {
      case .opaque:
        return .opaque
      case .transparent:
        return .transparent
      case .translucent:
        return .translucent
    }
  }
}
