import Foundation

public struct PlayerInfoPacket: ClientboundPacket {
  public static let id: Int = 0x33

  public var playerActions: [(uuid: UUID, action: PlayerInfoAction)]

  public enum PlayerInfoAction {
    case addPlayer(playerInfo: PlayerInfo)
    case updateGamemode(gamemode: Gamemode?)
    case updateLatency(ping: Int)
    case updateDisplayName(displayName: ChatComponent?)
    case removePlayer
  }

  public init(from packetReader: inout PacketReader) throws {
    let actionId = try packetReader.readVarInt()
    let numPlayers = try packetReader.readVarInt()
    playerActions = []
    for _ in 0..<numPlayers {
      let uuid = try packetReader.readUUID()
      let playerAction: PlayerInfoAction
      switch actionId {
        case 0: // add player
          let playerInfo = try Self.readPlayerInfo(from: &packetReader, uuid: uuid)
          playerAction = .addPlayer(playerInfo: playerInfo)
        case 1: // update gamemode
          let gamemode = try Self.readGamemode(from: &packetReader)
          playerAction = .updateGamemode(gamemode: gamemode)
        case 2: // update latency
          let ping = try packetReader.readVarInt()
          playerAction = .updateLatency(ping: ping)
        case 3: // update display name
          let displayName = try Self.readDisplayName(from: &packetReader)
          playerAction = .updateDisplayName(displayName: displayName)
        case 4: // remove player
          playerAction = .removePlayer
        default:
          log.warning("invalid player info action")
          continue
      }
      playerActions.append((uuid: uuid, action: playerAction))
    }
  }

  public func handle(for client: Client) throws {
    for playerAction in playerActions {
      let uuid = playerAction.uuid
      let action = playerAction.action

      switch action {
        case let .addPlayer(playerInfo: playerInfo):
          client.game.tabList.addPlayer(playerInfo)
        case let .updateGamemode(gamemode: gamemode):
          client.game.tabList.updateGamemode(gamemode, uuid: uuid)
        case let .updateLatency(ping: ping):
          client.game.tabList.updateLatency(ping, uuid: uuid)
        case let .updateDisplayName(displayName: displayName):
          client.game.tabList.updateDisplayName(displayName, uuid: uuid)
        case .removePlayer:
          client.game.tabList.removePlayer(uuid: uuid)
      }
    }
  }

  private static func readGamemode(from packetReader: inout PacketReader) throws -> Gamemode? {
    let rawValue = Int8(try packetReader.readVarInt())
    guard rawValue != -1 else {
      return nil
    }

    guard let gamemode = Gamemode(rawValue: rawValue) else {
      throw ClientboundPacketError.invalidGamemode(rawValue: rawValue)
    }

    return gamemode
  }

  private static func readDisplayName(from packetReader: inout PacketReader) throws -> ChatComponent? {
    var displayName: ChatComponent?
    if try packetReader.readBool() {
      displayName = try packetReader.readChat()
    }
    return displayName
  }

  private static func readPlayerInfo(from packetReader: inout PacketReader, uuid: UUID) throws -> PlayerInfo {
    let playerName = try packetReader.readString()

    let numProperties = try packetReader.readVarInt()
    var properties: [PlayerProperty] = []
    for _ in 0..<numProperties {
      let propertyName = try packetReader.readString()
      let value = try packetReader.readString()
      var signature: String?
      if try packetReader.readBool() {
        signature = try packetReader.readString()
      }
      let property = PlayerProperty(name: propertyName, value: value, signature: signature)
      properties.append(property)
    }

    let gamemode = try Self.readGamemode(from: &packetReader)
    let ping = try packetReader.readVarInt()
    let displayName = try Self.readDisplayName(from: &packetReader)

    return PlayerInfo(
      uuid: uuid,
      name: playerName,
      properties: properties,
      gamemode: gamemode,
      ping: ping,
      displayName: displayName
    )
  }
}
