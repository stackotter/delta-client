extension Direction: ProtobufCachableEnum {
  public init(from protobufEnum: ProtobufDirection) throws {
    switch protobufEnum {
      case .down:
        self = .down
      case .up:
        self = .up
      case .north:
        self = .north
      case .south:
        self = .south
      case .west:
        self = .west
      case .east:
        self = .east
      case .UNRECOGNIZED:
        throw BlockModelPaletteError.invalidDirection
    }
  }
  
  public func cached() -> ProtobufDirection {
    switch self {
      case .down:
        return .down
      case .up:
        return .up
      case .north:
        return .north
      case .south:
        return .south
      case .west:
        return .west
      case .east:
        return .east
    }
  }
}
