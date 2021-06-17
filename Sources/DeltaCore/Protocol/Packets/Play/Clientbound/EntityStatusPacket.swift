//
//  EntityStatusPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct EntityStatusPacket: ClientboundPacket {
  static let id: Int = 0x1b
  
  var entityId: Int
  var status: Int8
  
  init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readInt()
    status = packetReader.readByte()
  }
}
