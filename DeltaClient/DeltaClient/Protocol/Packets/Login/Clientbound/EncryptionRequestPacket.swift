//
//  EncryptionRequestPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct EncryptionRequestPacket: ClientboundPacket {
  static let id: Int = 0x01
  
  var serverId: String
  var publicKey: [UInt8]
  var verifyToken: [UInt8]

  init(from packetReader: inout PacketReader) throws {
    serverId = packetReader.readString()
    
    let publicKeyLength = packetReader.readVarInt()
    publicKey = packetReader.readByteArray(length: publicKeyLength)
    
    let verifyTokenLength = packetReader.readVarInt()
    verifyToken = packetReader.readByteArray(length: verifyTokenLength)
  }
}
