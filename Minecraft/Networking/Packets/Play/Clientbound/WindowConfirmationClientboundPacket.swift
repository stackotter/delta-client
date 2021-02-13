//
//  WindowConfirmationClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct WindowConfirmationClientboundPacket: ClientboundPacket {
  static let id: Int = 0x12
  
  var windowId: Int8
  var actionNumber: Int16
  var accepted: Bool
  
  init(fromReader packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    actionNumber = packetReader.readShort()
    accepted = packetReader.readBool()
  }
}
