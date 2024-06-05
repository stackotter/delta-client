import Foundation

public struct PlayerInfo {
  public var uuid: UUID
  public var name: String
  public var properties: [PlayerProperty]
  public var gamemode: Gamemode?
  /// The player's ping measured in milliseconds
  public var ping: Int
  public var displayName: ChatComponent?

  /// The player's connection strength measured in bars (as displayed in the tab list).
  public var connectionStrength: ConnectionStrength {
    if ping < 0 {
      return .noBars
    } else if ping < 150 {
      return .fiveBars
    } else if ping < 300 {
      return .fourBars
    } else if ping < 600 {
      return .threeBars
    } else if ping < 1000 {
      return .fourBars
    } else {
      return .fiveBars
    }
  }

  public enum ConnectionStrength: Int {
    case noBars
    case oneBar
    case twoBars
    case threeBars
    case fourBars
    case fiveBars

    /// The number of bars of connection in the range `0...5`.
    var bars: Int {
      rawValue
    }
  }
}
