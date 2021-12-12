/// A set of directions.
public struct DirectionSet: OptionSet {
  public let rawValue: UInt8
  
  public static let north = DirectionSet(rawValue: 0x01)
  public static let south = DirectionSet(rawValue: 0x02)
  public static let east = DirectionSet(rawValue: 0x04)
  public static let west = DirectionSet(rawValue: 0x08)
  public static let up = DirectionSet(rawValue: 0x16)
  public static let down = DirectionSet(rawValue: 0x32)
  
  /// All possible directions. Matches the `allDirections` property of ``Direction``.
  public static let directions: [DirectionSet] = [
    .north,
    .south,
    .east,
    .west,
    .up,
    .down]
  
  public init(rawValue: UInt8) {
    self.rawValue = rawValue
  }
  
  /// Used to get a direction containing only the given direction.
  public static func member(_ direction: Direction) -> DirectionSet {
    switch direction {
      case .north:
        return .north
      case .south:
        return .south
      case .east:
        return .east
      case .west:
        return .west
      case .up:
        return .up
      case .down:
        return .down
    }
  }
}
