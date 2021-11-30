extension Block.ComputedTintType: ProtobufCachableEnum {
  public init(from protobufEnum: ProtobufBlockComputedTintType) throws {
    switch protobufEnum {
      case .water:
        self = .waterTint
      case .foliage:
        self = .foliageTint
      case .grass:
        self = .grassTint
      case .sugarCane:
        self = .sugarCaneTint
      case .lilyPad:
        self = .lilyPadTint
      case .shearingDoublePlant:
        self = .shearingDoublePlantTint
      case .UNRECOGNIZED(let int):
        throw BlockRegistryError.invalidComputedTintType(int)
    }
  }
  
  public func cached() -> ProtobufBlockComputedTintType {
    switch self {
      case .waterTint:
        return .water
      case .foliageTint:
        return .foliage
      case .grassTint:
        return .grass
      case .sugarCaneTint:
        return .sugarCane
      case .lilyPadTint:
        return .lilyPad
      case .shearingDoublePlantTint:
        return .shearingDoublePlant
    }
  }
}
