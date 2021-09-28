//
//  PlayerInfoPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

public struct PlayerInfoPacket: ClientboundPacket {
  public static let id: Int = 0x33
  
  public var playerActions: [(uuid: UUID, action: PlayerInfoAction)]
  
  public enum PlayerInfoAction {
    case addPlayer(playerInfo: PlayerInfo)
    case updateGamemode(gamemode: Gamemode)
    case updateLatency(ping: Int)
    case updateDisplayName(displayName: ChatComponent?)
    case removePlayer
  }
  
  public init(from packetReader: inout PacketReader) throws {
    let actionId = packetReader.readVarInt()
    let numPlayers = packetReader.readVarInt()
    playerActions = []
    for _ in 0..<numPlayers {
      let uuid = try packetReader.readUUID()
      let playerAction: PlayerInfoAction
      switch actionId {
        case 0: // add player
          let playerName = try packetReader.readString()
          let numProperties = packetReader.readVarInt()
          var properties: [PlayerProperty] = []
          for _ in 0..<numProperties {
            let propertyName = try packetReader.readString()
            let value = try packetReader.readString()
            var signature: String?
            if packetReader.readBool() {
              signature = try packetReader.readString()
            }
            let property = PlayerProperty(name: propertyName, value: value, signature: signature)
            properties.append(property)
          }
          let gamemode = Gamemode(rawValue: Int8(packetReader.readVarInt())) ?? .none
          let ping = packetReader.readVarInt()
          var displayName: ChatComponent?
          if packetReader.readBool() {
            displayName = try packetReader.readChat()
          }
          let playerInfo = PlayerInfo(uuid: uuid, name: playerName, properties: properties, gamemode: gamemode, ping: ping, displayName: displayName)
          playerAction = .addPlayer(playerInfo: playerInfo)
        case 1: // update gamemode
          let gamemode = Gamemode(rawValue: Int8(packetReader.readVarInt())) ?? .none
          playerAction = .updateGamemode(gamemode: gamemode)
        case 2: // update latency
          let ping = packetReader.readVarInt()
          playerAction = .updateLatency(ping: ping)
        case 3: // update display name
          var displayName: ChatComponent?
          if packetReader.readBool() {
            displayName = try packetReader.readChat()
          }
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
          client.server?.tabList.addPlayer(playerInfo)
        case let .updateGamemode(gamemode: gamemode):
          client.server?.tabList.updateGamemode(gamemode, uuid: uuid)
        case let .updateLatency(ping: ping):
          client.server?.tabList.updateLatency(ping, uuid: uuid)
        case let .updateDisplayName(displayName: displayName):
          client.server?.tabList.updateDisplayName(displayName, uuid: uuid)
        case .removePlayer:
          client.server?.tabList.removePlayer(uuid: uuid)
      }
    }
  }
}
