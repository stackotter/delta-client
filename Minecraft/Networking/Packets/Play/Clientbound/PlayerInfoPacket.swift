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
    case addPlayer(action: AddPlayerAction)
    case updateGamemode(gamemode: Int32)
    case updateLatency(ping: Int32)
    case updateDisplayName(displayName: ChatComponent?)
    case removePlayer
    
    struct AddPlayerAction {
      var name: String
      var properties: [PlayerProperty]
      var gamemode: Int32
      var ping: Int32
      var displayName: ChatComponent?
    }
  }
  
  struct PlayerProperty {
    var name: String
    var value: String
    var signature: String?
  }
  
  init(fromReader packetReader: inout PacketReader) throws {
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
          let gamemode = packetReader.readVarInt()
          let ping = packetReader.readVarInt()
          var displayName: ChatComponent? = nil
          if packetReader.readBool() {
            displayName = packetReader.readChat()
          }
          let addPlayerAction = PlayerInfoAction.AddPlayerAction(name: playerName, properties: properties, gamemode: gamemode, ping: ping, displayName: displayName)
          playerAction = .addPlayer(action: addPlayerAction)
        case 1: // update gamemode
          let gamemode = packetReader.readVarInt()
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
}
