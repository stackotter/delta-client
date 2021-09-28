//
//  NameItemPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct NameItemPacket: ServerboundPacket {
  public static let id: Int = 0x1f
  
  public var itemName: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeString(itemName)
  }
}
