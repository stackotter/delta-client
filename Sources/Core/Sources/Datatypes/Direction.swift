import Foundation
import simd

/// A direction enum where the raw value is the same as in some of the Minecraft packets.
public enum Direction: Int {
  case down = 0
  case up = 1
  case north = 2
  case south = 3
  case west = 4
  case east = 5
  
  /// The array of all directions. Matches the order of ``DirectionSet/directions``.
  public static let allDirections: [Direction] = [
    .north,
    .south,
    .east,
    .west,
    .up,
    .down]
  
  /// All directions excluding up and down.
  public static let sides: [Direction] = [
    .north,
    .east,
    .south,
    .west]
  
  /// Returns the directions on the xz plane that are perpendicular to a direction.
  public var perpendicularXZ: [Direction] {
    switch self {
      case .north, .south:
        return [.east, .west]
      case .east, .west:
        return [.north, .south]
      case .up, .down:
        return [.north, .east, .south, .west]
    }
  }
  
  /// The axis this direction lies on.
  public var axis: Axis {
    switch self {
      case .west, .east:
        return .x
      case .up, .down:
        return .y
      case .north, .south:
        return .z
    }
  }
  
  /// Whether the direction is a positive direction in Minecraft's coordinate system or not.
  public var isPositive: Bool {
    switch self {
      case .up, .south, .east:
        return true
      case .down, .north, .west:
        return false
    }
  }
  
  /// The direction pointing the opposite direction to this one.
  public var opposite: Direction {
    switch self {
      case .down:
        return .up
      case .up:
        return .down
      case .north:
        return .south
      case .south:
        return .north
      case .east:
        return .west
      case .west:
        return .east
    }
  }
  
  /// Creates a direction from a string such as `"down"`.
  public init?(string: String) {
    switch string {
      case "down":
        self = .down
      case "up":
        self = .up
      case "north":
        self = .north
      case "south":
        self = .south
      case "west":
        self = .west
      case "east":
        self = .east
      default:
        return nil
    }
  }
  
  /// A normalized vector representing this direction.
  public var vector: SIMD3<Float> {
    SIMD3(intVector)
  }
  
  /// A normalized vector representing this direction.
  public var doubleVector: SIMD3<Double> {
    SIMD3(intVector)
  }
  
  /// A normalized vector representing this direction.
  public var intVector: SIMD3<Int> {
    switch self {
      case .down:
        return SIMD3<Int>(0, -1, 0)
      case .up:
        return SIMD3<Int>(0, 1, 0)
      case .north:
        return SIMD3<Int>(0, 0, -1)
      case .south:
        return SIMD3<Int>(0, 0, 1)
      case .west:
        return SIMD3<Int>(-1, 0, 0)
      case .east:
        return SIMD3<Int>(1, 0, 0)
    }
  }
  
  /// Returns the direction `n` 90 degree clockwise rotations around the axis while facing `referenceDirection`.
  public func rotated(_ n: Int, clockwiseFacing referenceDirection: Direction) -> Direction {
    // The three 'loops' of directions around the three axes. The directions are listed clockwise when looking in the negative direction along the axis.
    let loops: [Axis: [Direction]] = [
      .x: [.up, .north, .down, .south],
      .y: [.north, .east, .south, .west],
      .z: [.up, .east, .down, .west]]
    switch self {
      case referenceDirection, referenceDirection.opposite:
        return self
      default:
        // swiftlint:disable force_unwrap
        // This is safe because all axes are defined in the dictionary
        let loop = loops[referenceDirection.axis]!
        // This is safe because all four directions that are handled by this case will be in the loop
        let index = loop.firstIndex(of: self)!
        // swiftlint:enable force_unwrap
        var newIndex: Int
        if referenceDirection.isPositive {
          newIndex = index - n
        } else {
          newIndex = index + n
        }
        newIndex = MathUtil.mod(newIndex, loop.count)
        return loop[newIndex]
    }
  }
}
