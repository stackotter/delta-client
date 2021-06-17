//
//  LockDifficultyPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct LockDifficultyPacket: ServerboundPacket {
  static let id: Int = 0x11
  
  var locked: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(locked)
  }
}
