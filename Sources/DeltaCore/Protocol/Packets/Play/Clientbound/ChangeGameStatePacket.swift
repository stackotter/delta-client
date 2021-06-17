//
//  ChangeGameStatePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

struct ChangeGameStatePacket: ClientboundPacket {
  static let id: Int = 0x1e
  
  var reason: UInt8
  var value: Float
  
  init(from packetReader: inout PacketReader) throws {
    reason = packetReader.readUnsignedByte()
    value = packetReader.readFloat()
  }
}
