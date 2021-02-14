//
//  SelectAdvancementTabPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SelectAdvancementTabPacket: ClientboundPacket {
  static let id: Int = 0x3c
  
  var identifier: Identifier?

  init(fromReader packetReader: inout PacketReader) throws {
    if packetReader.readBool() {
      identifier = try packetReader.readIdentifier()
    }
  }
}
