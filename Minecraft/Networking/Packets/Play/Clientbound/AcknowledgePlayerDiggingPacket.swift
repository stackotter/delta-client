//
//  AcknowledgePlayerDiggingPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct AcknowledgePlayerDiggingPacket: ClientboundPacket {
  static let id: Int = 0x07
  
  var location: Position
  var block: Int32
  var status: Int32
  var successful: Bool
  
  init(fromReader packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    block = packetReader.readVarInt()
    status = packetReader.readVarInt()
    successful = packetReader.readBool()
  }
}
