import Foundation

public struct PlayerInfo {
  public var uuid: UUID
  public var name: String
  public var properties: [PlayerProperty]
  public var gamemode: Gamemode?
  public var ping: Int
  public var displayName: ChatComponent?
}
