//
//  PlayerInfoPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation
import os

struct PlayerInfoPacket: ClientboundPacket {
  static let id: Int = 0x33
  
  var playerActions: [(uuid: UUID, action: PlayerInfoAction)]
  
  enum PlayerInfoAction {
    case addPlayer(playerInfo: PlayerInfo)
    case updateGamemode(gamemode: Gamemode)
    case updateLatency(ping: Int32)
    case updateDisplayName(displayName: ChatComponent?)
    case removePlayer
  }
  
  init(from packetReader: inout PacketReader) throws {
    let actionId = packetReader.readVarInt()
    let numPlayers = packetReader.readVarInt()
    playerActions = []
    for _ in 0..<numPlayers {
      let uuid = packetReader.readUUID()
      let playerAction: PlayerInfoAction
      switch actionId {
        case 0: // add player
          let playerName = packetReader.readString()
          let numProperties = packetReader.readVarInt()
          var properties: [PlayerProperty] = []
          for _ in 0..<numProperties {
            let propertyName = packetReader.readString()
            let value = packetReader.readString()
            var signature: String? = nil
            if packetReader.readBool() {
              signature = packetReader.readString()
            }
            let property = PlayerProperty(name: propertyName, value: value, signature: signature)
            properties.append(property)
          }
          let gamemode = Gamemode(rawValue: Int8(packetReader.readVarInt())) ?? .none
          let ping = packetReader.readVarInt()
          var displayName: ChatComponent? = nil
          if packetReader.readBool() {
            displayName = packetReader.readChat()
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
          var displayName: ChatComponent? = nil
          if packetReader.readBool() {
            displayName = packetReader.readChat()
          }
          playerAction = .updateDisplayName(displayName: displayName)
        case 4: // remove player
          playerAction = .removePlayer
        default:
          Logger.debug("invalid player info action")
          continue
      }
      playerActions.append((uuid: uuid, action: playerAction))
    }
  }
  
  func handle(for server: Server) throws {
    for playerAction in playerActions {
      let uuid = playerAction.uuid
      let action = playerAction.action
      
      switch action {
        case let .addPlayer(playerInfo: playerInfo):
          server.tabList.addPlayer(playerInfo)
        case let .updateGamemode(gamemode: gamemode):
          server.tabList.updateGamemode(gamemode, uuid: uuid)
        case let .updateLatency(ping: ping):
          server.tabList.updateLatency(ping, uuid: uuid)
        case let .updateDisplayName(displayName: displayName):
          server.tabList.updateDisplayName(displayName, uuid: uuid)
        case .removePlayer:
          server.tabList.removePlayer(uuid: uuid)
      }
    }
  }
}
