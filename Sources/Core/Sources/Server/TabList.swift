import Foundation

/// A list of all players currently connected to a server.
public struct TabList {
  /// The currently connected players.
  public private(set) var players: [UUID: PlayerInfo] = [:]

  /// Adds a player to the tab list.
  public mutating func addPlayer(_ playerInfo: PlayerInfo) {
    players[playerInfo.uuid] = playerInfo
  }

  /// Updates the gamemode of a player in the tab list.
  public mutating func updateGamemode(_ gamemode: Gamemode?, uuid: UUID) {
    players[uuid]?.gamemode = gamemode
  }

  /// Updates the latency of a player in the tab list.
  public mutating func updateLatency(_ ping: Int, uuid: UUID) {
    players[uuid]?.ping = ping
  }

  /// Updates the display name of a player in the tab list.
  public mutating func updateDisplayName(_ displayName: ChatComponent?, uuid: UUID) {
    players[uuid]?.displayName = displayName
  }

  /// Removes the specified player from the tab list.
  public mutating func removePlayer(uuid: UUID) {
    players.removeValue(forKey: uuid)
  }
}
