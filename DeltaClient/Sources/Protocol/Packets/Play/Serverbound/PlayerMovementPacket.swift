//
//  PlayerMovementPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct PlayerMovementPacket: ServerboundPacket {
  static let id: Int = 0x15
  
  var onGround: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(onGround)
  }
}
