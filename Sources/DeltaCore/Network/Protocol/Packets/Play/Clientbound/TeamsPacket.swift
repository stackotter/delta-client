//
//  TeamsPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 20/2/21.
//

import Foundation

public struct TeamsPacket: ClientboundPacket {
  public static let id: Int = 0x4c
  
  public var teamName: String
  public var action: TeamAction
  
  public enum TeamAction {
    case create(action: Create)
    case remove
    case updateInfo(action: UpdateInfo)
    case addPlayers(entities: [String])
    case removePlayers(entities: [String])
    
    public struct Create {
      public var teamDisplayName: ChatComponent
      public var friendlyFlags: Int8
      public var nameTagVisibility: String
      public var collisionRule: String
      public var teamColor: Int
      public var teamPrefix: ChatComponent
      public var teamSuffix: ChatComponent
      public var entities: [String]
    }
    
    public struct UpdateInfo {
      public var teamDisplayName: ChatComponent
      public var friendlyFlags: Int8
      public var nameTagVisibility: String
      public var collisionRule: String
      public var teamColor: Int
      public var teamPrefix: ChatComponent
      public var teamSuffix: ChatComponent
    }
  }

  public init(from packetReader: inout PacketReader) throws {
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
        log.debug("invalid team action")
        action = .remove
    }
  }
}
