//
//  PlayerPositionAndLookClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct PlayerPositionAndLookClientboundPacket: ClientboundPacket {
  static let id: Int = 0x35
  
  var position: EntityPosition
  var look: EntityRotation
  var flags: PositionAndLookFlags
  var teleportId: Int32
  
  struct PositionAndLookFlags: OptionSet {
    let rawValue: UInt8
    
    static let x = PositionAndLookFlags(rawValue: 0x01)
    static let y = PositionAndLookFlags(rawValue: 0x02)
    static let z = PositionAndLookFlags(rawValue: 0x04)
    static let yRot = PositionAndLookFlags(rawValue: 0x08)
    static let xRot = PositionAndLookFlags(rawValue: 0x10)
  }

  init(fromReader packetReader: inout PacketReader) throws {
    position = packetReader.readEntityPosition()
    look = packetReader.readEntityRotation()
    flags = PositionAndLookFlags(rawValue: packetReader.readUnsignedByte())
    teleportId = packetReader.readVarInt()
  }
}
