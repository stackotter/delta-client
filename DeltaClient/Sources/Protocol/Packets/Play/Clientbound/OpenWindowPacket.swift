//
//  OpenWindowPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

struct OpenWindowPacket: ClientboundPacket {
  static let id: Int = 0x2e
  
  var windowId: Int
  var windowType: Int
  var windowTitle: ChatComponent
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readVarInt()
    windowType = packetReader.readVarInt()
    windowTitle = packetReader.readChat()
  }
}
