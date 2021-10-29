/// A component storing a player's gamemode.
public struct PlayerGamemode {
  /// The player's gamemode.
  public var gamemode: Gamemode
  
  /// Creates a player's gamemode.
  /// - Parameter gamemode: Defaults to survival.
  public init(gamemode: Gamemode = .survival) {
    self.gamemode = gamemode
  }
}
