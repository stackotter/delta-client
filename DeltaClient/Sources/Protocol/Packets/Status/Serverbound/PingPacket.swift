//
//  PingPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct PingPacket: ServerboundPacket {
  static let id: Int = 0x01
  
  var payload: Int
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeLong(Int64(payload))
  }
}
