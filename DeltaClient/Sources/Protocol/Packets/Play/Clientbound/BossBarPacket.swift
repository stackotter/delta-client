//
//  BossBarPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation


struct BossBarPacket: ClientboundPacket {
  static let id: Int = 0x0c
  
  var uuid: UUID
  var action: BossBarAction
  
  enum BossBarAction {
    case add(title: ChatComponent, health: Float, color: Int, division: Int, flags: UInt8)
    case remove
    case updateHealth(health: Float)
    case updateTitle(title: ChatComponent)
    case updateStyle(color: Int, division: Int)
    case updateFlags(flags: UInt8)
  }
  
  init(from packetReader: inout PacketReader) throws {
    uuid = try packetReader.readUUID()
    let actionId = packetReader.readVarInt()
    
    switch actionId {
      case 0:
        let title = try packetReader.readChat()
        let health = packetReader.readFloat()
        let color = packetReader.readVarInt()
        let division = packetReader.readVarInt()
        let flags = packetReader.readUnsignedByte()
        action = .add(title: title, health: health, color: color, division: division, flags: flags)
      case 1:
        action = .remove
      case 2:
        let health = packetReader.readFloat()
        action = .updateHealth(health: health)
      case 3:
        let title = try packetReader.readChat()
        action = .updateTitle(title: title)
      case 4:
        let color = packetReader.readVarInt()
        let division = packetReader.readVarInt()
        action = .updateStyle(color: color, division: division)
      case 5:
        let flags = packetReader.readUnsignedByte()
        action = .updateFlags(flags: flags)
      default:
        log.warning("invalid boss bar action id")
        action = .remove
    }
  }
}
