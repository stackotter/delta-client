//
//  LoginPluginResponse.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct LoginPluginResponse: ServerboundPacket {
  static let id: Int = 0x02
  
  var messageId: Int
  var wasSuccess: Bool
  var data: [UInt8]
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(messageId))
    writer.writeBool(!data.isEmpty ? wasSuccess : false)
    writer.writeByteArray(data)
  }
}
