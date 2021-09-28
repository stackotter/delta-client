//
//  ChangeGameStatePacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct ChangeGameStatePacket: ClientboundPacket {
  public static let id: Int = 0x1e
  
  public var reason: UInt8
  public var value: Float
  
  public init(from packetReader: inout PacketReader) throws {
    reason = packetReader.readUnsignedByte()
    value = packetReader.readFloat()
  }
}
