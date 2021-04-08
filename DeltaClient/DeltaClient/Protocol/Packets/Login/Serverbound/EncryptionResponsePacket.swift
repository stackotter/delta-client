//
//  EncryptionResponsePacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct EncryptionResponsePacket: ServerboundPacket {
  static let id: Int = 0x01
  
  var sharedSecret: [UInt8]
  var verifyToken: [UInt8]
  
  func writePayload(to writer: inout PacketWriter) {
    writer.writeVarInt(Int32(sharedSecret.count))
    writer.writeByteArray(sharedSecret)
    writer.writeVarInt(Int32(verifyToken.count))
    writer.writeByteArray(verifyToken)
  }
}
