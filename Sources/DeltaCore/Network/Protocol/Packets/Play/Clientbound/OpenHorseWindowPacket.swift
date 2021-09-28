//
//  OpenHorseWindowPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct OpenHorseWindowPacket: ClientboundPacket {
  public static let id: Int = 0x1f
  
  public var windowId: Int8
  public var numberOfSlots: Int
  public var entityId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    numberOfSlots = packetReader.readVarInt()
    entityId = packetReader.readInt()
  }
}
