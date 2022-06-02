import Foundation

/// An enum used when decoding Mojang formatted block models from JSON.
public enum JSONBlockModelFaceName: String, Codable {
  case down
  case up
  case north
  case south
  case west
  case east
  
  public init?(rawValue: String) {
    // Why Mojang, did you have to make both 'down' and 'bottom' valid and on top of that,
    // only use bottom once in all of the vanilla assets?
    switch rawValue {
      case "down", "bottom":
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
  
  var direction: Direction {
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
