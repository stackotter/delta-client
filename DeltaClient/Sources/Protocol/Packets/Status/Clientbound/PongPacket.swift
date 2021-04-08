//
//  PongPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct PongPacket: ClientboundPacket {
  static let id: Int = 0x01
  
  var payload: Int
  
  init(from packetReader: inout PacketReader) throws {
    payload = packetReader.readLong()
  }
}
