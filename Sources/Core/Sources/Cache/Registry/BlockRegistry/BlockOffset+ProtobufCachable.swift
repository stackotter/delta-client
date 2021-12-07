extension Block.Offset: ProtobufCachableEnum {
  public init(from protobufEnum: ProtobufBlockOffset) throws {
    switch protobufEnum {
      case .xyz:
        self = .xyz
      case .xz:
        self = .xz
      case .UNRECOGNIZED:
        throw BlockModelPaletteError.invalidBlockOffset
    }
  }
  
  public func cached() -> ProtobufBlockOffset {
    switch self {
      case .xyz:
        return .xyz
      case .xz:
        return .xz
    }
  }
}
