//
//  WindowPropertyPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct WindowPropertyPacket: ClientboundPacket {
  static let id: Int = 0x15
  
  var windowId: UInt8
  var property: Int16
  var value: Int16
  
  init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readUnsignedByte()
    property = packetReader.readShort()
    value = packetReader.readShort()
  }
}
