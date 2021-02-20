//
//  OpenWindowPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct OpenWindowPacket: ClientboundPacket {
  static let id: Int = 0x2e
  
  var windowId: Int32
  var windowType: Int32
  var windowTitle: String
  
  init(fromReader packetReader: inout PacketReader) throws {
    windowId = packetReader.readVarInt()
    windowType = packetReader.readVarInt()
    windowTitle = try packetReader.readChat()
  }
}
