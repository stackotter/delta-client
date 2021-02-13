//
//  LoginSuccess.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginSuccess: ClientboundPacket {
  static let id: Int = 0x02
  
  var uuid: UUID
  var username: String
  
  init(fromReader packetReader: inout PacketReader) {
    uuid = packetReader.readUUID()
    username = packetReader.readString()
  }
}

