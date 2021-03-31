//
//  CloseWindowClientboundPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct CloseWindowClientboundPacket: ClientboundPacket {
  static let id: Int = 0x13
  
  var windowId: UInt8
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readUnsignedByte()
  }
}
