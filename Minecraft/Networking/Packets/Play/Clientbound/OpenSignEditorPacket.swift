//
//  OpenSignEditorPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/2/21.
//

import Foundation

struct OpenSignEditorPacket: ClientboundPacket {
  static let id: Int = 0x2f
  
  var location: Position
  
  init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
}
