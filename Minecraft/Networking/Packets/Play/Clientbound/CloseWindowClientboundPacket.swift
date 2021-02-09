//
//  CloseWindowClientboundPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct CloseWindowClientboundPacket: Packet {
  typealias PacketType = CloseWindowClientboundPacket
  static let id: Int = 0x13
  
  var windowId: UInt8
  
  init(fromReader packetReader: inout PacketReader) throws {
    windowId = packetReader.readUnsignedByte()
  }
}
