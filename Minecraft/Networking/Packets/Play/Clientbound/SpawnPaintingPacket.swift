//
//  SpawnPaintingPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct SpawnPaintingPacket: Packet {
  typealias PacketType = SpawnPaintingPacket
  static let id: Int =  0x03
  
  var entityId: Int32
  var entityUUID: UUID
  var motive: Int32
  var location: Position
  var direction: UInt8 // TODO_LATER
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = packetReader.readUUID()
    motive = packetReader.readVarInt()
    location = packetReader.readPosition()
    direction = packetReader.readUnsignedByte()
  }
}
