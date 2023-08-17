import Foundation
import FirebladeMath

/// A direction enum where the raw value is the same as in some of the Minecraft packets.
public enum Direction: Int, CustomStringConvertible {
  case down = 0
  case up = 1
  case north = 2
  case south = 3
  case west = 4
  case east = 5

  /// The array of all directions.
  public static let allDirections: [Direction] = [
    .north,
    .south,
    .east,
    .west,
    .up,
    .down
  ]

  /// All directions excluding up and down.
  public static let sides: [Direction] = [
    .north,
    .east,
    .south,
    .west
  ]

  public var description: String {
    switch self {
      case .down:
        return "down"
      case .up:
        return "up"
      case .north:
        return "north"
      case .south:
        return "south"
      case .west:
        return "west"
      case .east:
        return "east"
    }
  }

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
  public var vector: Vec3f {
    Vec3f(intVector)
  }

  /// A normalized vector representing this direction.
  public var doubleVector: Vec3d {
    Vec3d(intVector)
  }

  /// A normalized vector representing this direction.
  public var intVector: Vec3i {
    switch self {
      case .down:
        return Vec3i(0, -1, 0)
      case .up:
        return Vec3i(0, 1, 0)
      case .north:
        return Vec3i(0, 0, -1)
      case .south:
        return Vec3i(0, 0, 1)
      case .west:
        return Vec3i(-1, 0, 0)
      case .east:
        return Vec3i(1, 0, 0)
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
        // This is safe because all axes are defined in the dictionary
        let loop = loops[referenceDirection.axis]!
        // This is safe because all four directions that are handled by this case will be in the loop
        let index = loop.firstIndex(of: self)!
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

extension Direction: Codable {
  public init(from decoder: Decoder) throws {
    let string = try decoder.singleValueContainer().decode(String.self)
    guard let direction = Direction(string: string) else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid direction '\(string)'"
        )
      )
    }
    self = direction
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
