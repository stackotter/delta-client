//
//  SetCompressionPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct SetCompressionPacket: ClientboundPacket {
  static let id: Int = 0x03

  var threshold: Int
  
  init(from packetReader: inout PacketReader) throws {
    threshold = packetReader.readVarInt()
  }
}
