//
//  LoginPluginRequestPacket.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct LoginPluginRequestPacket: ClientboundPacket {
  static let id: Int = 0x04
  
  var messageId: Int
  var channel: Identifier
  var data: [UInt8]

  init(from packetReader: inout PacketReader) throws {
    messageId = packetReader.readVarInt()
    channel = try packetReader.readIdentifier()
    data = packetReader.readByteArray(length: packetReader.remaining)
  }
}
