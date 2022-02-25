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
