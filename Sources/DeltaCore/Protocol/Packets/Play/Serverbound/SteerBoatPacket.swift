//
//  SteerBoatPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SteerBoatPacket: ServerboundPacket {
  static let id: Int = 0x17
  
  var isLeftPaddleTurning: Bool
  var isRightPaddleTurning: Bool
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeBool(isLeftPaddleTurning)
    writer.writeBool(isRightPaddleTurning)
  }
}
