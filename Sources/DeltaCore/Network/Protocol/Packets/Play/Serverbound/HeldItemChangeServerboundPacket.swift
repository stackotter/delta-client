//
//  HeldItemChangeServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct HeldItemChangeServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x24
  
  public var slot: Int16
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeShort(slot)
  }
}
