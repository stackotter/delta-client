//
//  WindowConfirmationServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct WindowConfirmationServerboundPacket: ServerboundPacket {
  static let id: Int = 0x07
  
  var windowId: Int8
  var actionNumber: Int16
  var accepted: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeByte(windowId)
    writer.writeShort(actionNumber)
    writer.writeBool(accepted)
  }
}
