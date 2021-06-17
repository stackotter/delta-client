//
//  CloseWindowServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct CloseWindowServerboundPacket: ServerboundPacket {
  static let id: Int = 0x0a
  
  var windowId: UInt8
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeUnsignedByte(windowId)
  }
}
