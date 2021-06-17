//
//  SelectAdvancementTabPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct SelectAdvancementTabPacket: ClientboundPacket {
  static let id: Int = 0x3c
  
  var identifier: Identifier?

  init(from packetReader: inout PacketReader) throws {
    if packetReader.readBool() {
      identifier = try packetReader.readIdentifier()
    }
  }
}
