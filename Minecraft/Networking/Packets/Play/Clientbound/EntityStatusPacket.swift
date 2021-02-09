//
//  EntityStatusPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct EntityStatusPacket: Packet {
  typealias PacketType = EntityStatusPacket
  static let id: Int = 0x1b
  
  var entityId: Int32
  var status: Int8
  
  init(fromReader packetReader: inout PacketReader) throws {
    entityId = packetReader.readInt()
    status = packetReader.readByte()
  }
}
