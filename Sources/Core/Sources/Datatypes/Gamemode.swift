import Foundation

/// The player's gamemode. Each gamemode gives the player different abilities.
public enum Gamemode: Int8 {
  case survival = 0
  case creative = 1
  case adventure = 2
  case spectator = 3
  
  /// - Returns: Whether the player is always flying when in this gamemode.
  public var isAlwaysFlying: Bool {
    return self == .spectator
  }
}
