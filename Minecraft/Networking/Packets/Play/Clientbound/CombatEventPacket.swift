//
//  CombatEventPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct CombatEventPacket: ClientboundPacket {
  static let id: Int = 0x32
  
  var event: CombatEvent?
  
  enum CombatEvent {
    case enterCombat
    case endCombat(duration: Int32, entityId: Int32)
    case entityDead(playerId: Int32, entityId: Int32, message: ChatComponent)
  }
  
  init(fromReader packetReader: inout PacketReader) throws {
    let eventId = packetReader.readVarInt()
    switch eventId {
      case 0: // enter combat
        event = .enterCombat
      case 1: // end combat
        let duration = packetReader.readVarInt()
        let entityId = packetReader.readInt()
        event = .endCombat(duration: duration, entityId: entityId)
      case 2: // entity dead
        let playerId = packetReader.readVarInt()
        let entityId = packetReader.readInt()
        let message = packetReader.readChat()
        event = .entityDead(playerId: playerId, entityId: entityId, message: message)
      default:
        event = nil
    }
  }
}
