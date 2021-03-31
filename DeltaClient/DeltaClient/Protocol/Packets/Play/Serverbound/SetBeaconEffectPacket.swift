//
//  SetBeaconEffectPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SetBeaconEffectPacket: ServerboundPacket {
  static let id: Int = 0x23
  
  var primaryEffect: Int32
  var secondaryEffect: Int32
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(primaryEffect)
    writer.writeVarInt(secondaryEffect)
  }
}
