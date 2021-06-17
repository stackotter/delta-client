//
//  SpectatePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SpectatePacket: ServerboundPacket {
  static let id: Int = 0x2c
  
  var targetPlayer: UUID
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeUUID(targetPlayer)
  }
}
