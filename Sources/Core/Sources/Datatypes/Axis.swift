import Foundation

/// An axis
public enum Axis: CaseIterable {
  case x
  case y
  case z

  /// The positive direction along this axis in Minecraft's coordinate system.
  public var positiveDirection: Direction {
    switch self {
      case .x:
        return .east
      case .y:
        return .up
      case .z:
        return .south
    }
  }

  /// The negative direction along this axis in Minecraft's coordinate system.
  public var negativeDirection: Direction {
    switch self {
      case .x:
        return .west
      case .y:
        return .down
      case .z:
        return .north
    }
  }

  /// The conventional indices assigned to the axis, i.e. x -> 0, y -> 1, z -> 2
  public var index: Int {
    switch self {
      case .x:
        return 0
      case .y:
        return 1
      case .z:
        return 2
    }
  }
}
