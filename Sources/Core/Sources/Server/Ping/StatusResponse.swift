import Foundation

/// A status response from the server. See ``StatusResponsePacket``.
public struct StatusResponse: Decodable {
  /// The server's version.
  public struct Version: Decodable {
    /// The name of the version. For example "1.16.1".
    public var name: String
    /// The protocol version. For example 758.
    public var protocolVersion: Int
    
    public enum CodingKeys: String, CodingKey {
      case name
      case protocolVersion = "protocol"
    }
  }
  
  /// Information about the online players.
  public struct PlayerList: Decodable {
    /// The maximum number of online players allowed.
    public var max: Int
    /// The number of online players.
    public var online: Int
    /// A sample of the online players (does not necessarily contain all online players).
    public var sample: [OnlinePlayer]?
    
    /// Information about an online player.
    public struct OnlinePlayer: Decodable {
      /// The player's username.
      public var name: String
      /// The player's uuid.
      public var id: String
    }
  }
  
  /// The server's description.
  public struct Description: Decodable {
    /// The description styled as legacy text.
    public var text: String
    
    public enum CodingKeys: String, CodingKey {
      case text
    }
    
    public init(from decoder: Decoder) throws {
      if let container = try? decoder.container(keyedBy: CodingKeys.self) {
        text = try container.decode(String.self, forKey: .text)
      } else if let container = try? decoder.singleValueContainer() {
        text = try container.decode(String.self)
      } else {
        text = "A Minecraft Server"
      }
    }
  }
  
  /// The server's version
  public var version: Version
  /// Information about the online players.
  public var players: PlayerList
  /// The server's message of the day.
  public var description: Description
  /// The server's icon.
  public var favicon: String?
  
  public init(version: StatusResponse.Version, players: StatusResponse.PlayerList, description: StatusResponse.Description, favicon: String) {
    self.version = version
    self.players = players
    self.description = description
    self.favicon = favicon
  }
}
