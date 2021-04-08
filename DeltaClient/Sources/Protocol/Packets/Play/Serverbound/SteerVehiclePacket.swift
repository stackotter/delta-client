//
//  SteerVehiclePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

struct SteerVehiclePacket: ServerboundPacket {
  static let id: Int = 0x1d
  
  var sideways: Float
  var forward: Float
  var flags: UInt8
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeFloat(sideways)
    writer.writeFloat(forward)
    writer.writeUnsignedByte(flags)
  }
}
