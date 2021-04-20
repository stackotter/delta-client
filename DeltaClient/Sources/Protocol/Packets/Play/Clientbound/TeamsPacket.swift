//
//  TeamsPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation


struct TeamsPacket: ClientboundPacket {
  static let id: Int = 0x4c
  
  var teamName: String
  var action: TeamAction
  enum TeamAction {
    case create(action: Create)
    case remove
    case updateInfo(action: UpdateInfo)
    case addPlayers(entities: [String])
    case removePlayers(entities: [String])
    
    struct Create {
      var teamDisplayName: ChatComponent
      var friendlyFlags: Int8
      var nameTagVisibility: String
      var collisionRule: String
      var teamColor: Int
      var teamPrefix: ChatComponent
      var teamSuffix: ChatComponent
      var entities: [String]
    }
    
    struct UpdateInfo {
      var teamDisplayName: ChatComponent
      var friendlyFlags: Int8
      var nameTagVisibility: String
      var collisionRule: String
      var teamColor: Int
      var teamPrefix: ChatComponent
      var teamSuffix: ChatComponent
    }
  }

  init(from packetReader: inout PacketReader) throws {
    teamName = try packetReader.readString()
    let mode = packetReader.readByte()
    switch mode {
      case 0: // create
        let teamDisplayName = try packetReader.readChat()
        let friendlyFlags = packetReader.readByte()
        let nameTagVisibility = try packetReader.readString()
        let collisionRule = try packetReader.readString()
        let teamColor = packetReader.readVarInt()
        let teamPrefix = try packetReader.readChat()
        let teamSuffix = try packetReader.readChat()
        let entityCount = packetReader.readVarInt()
        var entities: [String] = []
        for _ in 0..<entityCount {
          let entity = try packetReader.readString()
          entities.append(entity)
        }
        let createAction = TeamAction.Create(
          teamDisplayName: teamDisplayName, friendlyFlags: friendlyFlags,
          nameTagVisibility: nameTagVisibility, collisionRule: collisionRule,
          teamColor: teamColor, teamPrefix: teamPrefix, teamSuffix: teamSuffix,
          entities: entities
        )
        action = .create(action: createAction)
      case 1: // remove
        action = .remove
      case 2: // update info
        let teamDisplayName = try packetReader.readChat()
        let friendlyFlags = packetReader.readByte()
        let nameTagVisibility = try packetReader.readString()
        let collisionRule = try packetReader.readString()
        let teamColor = packetReader.readVarInt()
        let teamPrefix = try packetReader.readChat()
        let teamSuffix = try packetReader.readChat()
        let updateInfoAction = TeamAction.UpdateInfo(
          teamDisplayName: teamDisplayName, friendlyFlags: friendlyFlags,
          nameTagVisibility: nameTagVisibility, collisionRule: collisionRule,
          teamColor: teamColor, teamPrefix: teamPrefix, teamSuffix: teamSuffix
        )
        action = .updateInfo(action: updateInfoAction)
      case 3: // add players
        let entityCount = packetReader.readVarInt()
        var entities: [String] = []
        for _ in 0..<entityCount {
          let entity = try packetReader.readString()
          entities.append(entity)
        }
        action = .addPlayers(entities: entities)
      case 4: // remove players
        let entityCount = packetReader.readVarInt()
        var entities: [String] = []
        for _ in 0..<entityCount {
          let entity = try packetReader.readString()
          entities.append(entity)
        }
        action = .removePlayers(entities: entities)
      default:
        Logger.debug("invalid team action")
        action = .remove
    }
  }
}
