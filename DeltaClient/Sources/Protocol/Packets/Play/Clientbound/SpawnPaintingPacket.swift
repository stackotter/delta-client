//
//  SpawnPaintingPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct SpawnPaintingPacket: ClientboundPacket {
  static let id: Int =  0x03
  
  var entityId: Int
  var entityUUID: UUID
  var motive: Int
  var location: Position
  var direction: UInt8 // TODO_LATER
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = packetReader.readUUID()
    motive = packetReader.readVarInt()
    location = packetReader.readPosition()
    direction = packetReader.readUnsignedByte()
  }
}
