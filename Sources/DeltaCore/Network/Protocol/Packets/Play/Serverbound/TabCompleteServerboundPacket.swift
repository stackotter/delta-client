//
//  TabCompleteServerboundPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 21/2/21.
//

import Foundation

public struct TabCompleteServerboundPacket: ServerboundPacket {
  public static let id: Int = 0x06
  
  public var transactionId: Int32
  public var text: String
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(transactionId)
    writer.writeString(text)
  }
}
