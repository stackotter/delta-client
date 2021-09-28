//
//  SetSlotPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation

public struct SetSlotPacket: ClientboundPacket {
  public static let id: Int = 0x16
  
  public var windowId: Int8
  public var slot: Int16
  public var slotData: ItemStack
  
  public init(from packetReader: inout PacketReader) throws {
    windowId = packetReader.readByte()
    slot = packetReader.readShort()
    slotData = try packetReader.readItemStack()
  }
}
