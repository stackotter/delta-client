//
//  ClickWindowButtonPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct ClickWindowButtonPacket: ServerboundPacket {
  static let id: Int = 0x08
  
  var windowId: Int8
  var buttonId: Int8
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeByte(windowId)
    writer.writeByte(buttonId)
  }
}
