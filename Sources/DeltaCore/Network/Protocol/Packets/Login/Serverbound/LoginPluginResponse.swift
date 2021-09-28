//
//  LoginPluginResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

public struct LoginPluginResponse: ServerboundPacket {
  public static let id: Int = 0x02
  
  public var messageId: Int
  public var wasSuccess: Bool
  public var data: [UInt8]
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(messageId))
    writer.writeBool(!data.isEmpty ? wasSuccess : false)
    writer.writeByteArray(data)
  }
}
