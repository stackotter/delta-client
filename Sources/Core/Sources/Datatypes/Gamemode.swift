import Foundation

/// The player's gamemode. Each gamemode gives the player different abilities.
public enum Gamemode: Int8 {
  case survival = 0
  case creative = 1
  case adventure = 2
  case spectator = 3
  
  /// Whether the player is always flying when in this gamemode.
  public var isAlwaysFlying: Bool {
    return self == .spectator
  }

  /// Whether the player collides with the world or not when in this gamemode.
  public var hasCollisions: Bool {
    return self != .spectator
  }

  /// Whether the gamemode has visible health.
  public var hasHealth: Bool {
    switch self {
      case .survival, .adventure:
        return true
      case .creative, .spectator:
        return false
    }
  }

  public var canBreakBlocks: Bool {
    switch self {
      case .survival, .creative:
        return true
      case .adventure, .spectator:
        return false
    }
  }

  public var canPlaceBlocks: Bool {
    switch self {
      case .survival, .creative:
        return true
      case .adventure, .spectator:
        return false
    }
  }

  /// The lowercase string representation of the gamemode.
  public var string: String {
    switch self {
      case .survival: return "survival"
      case .creative: return "creative"
      case .adventure: return "adventure"
      case .spectator: return "spectator"
    }
  }
}
