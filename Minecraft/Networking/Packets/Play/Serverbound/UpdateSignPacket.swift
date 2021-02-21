//
//  UpdateSignPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct UpdateSignPacket: ServerboundPacket {
  static let id: Int = 0x2a
  
  var location: Position
  var line1: String
  var line2: String
  var line3: String
  var line4: String
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writePosition(location)
    writer.writeString(line1)
    writer.writeString(line2)
    writer.writeString(line3)
    writer.writeString(line4)
  }
}
