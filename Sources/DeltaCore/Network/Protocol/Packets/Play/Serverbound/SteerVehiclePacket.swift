//
//  SteerVehiclePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct SteerVehiclePacket: ServerboundPacket {
  public static let id: Int = 0x1d
  
  public var sideways: Float
  public var forward: Float
  public var flags: UInt8
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeFloat(sideways)
    writer.writeFloat(forward)
    writer.writeUnsignedByte(flags)
  }
}
