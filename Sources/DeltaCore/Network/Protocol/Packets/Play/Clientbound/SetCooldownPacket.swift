//
//  SetCooldownPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct SetCooldownPacket: ClientboundPacket {
  public static let id: Int = 0x17
  
  public var itemId: Int
  public var cooldownTicks: Int
  
  public init(from packetReader: inout PacketReader) throws {
    itemId = packetReader.readVarInt()
    cooldownTicks = packetReader.readVarInt()
  }
}
