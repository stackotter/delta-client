//
//  LoginSuccessPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginSuccessPacket: ClientboundPacket {
  static let id: Int = 0x02
  
  var uuid: UUID
  var username: String
  
  init(fromReader packetReader: inout PacketReader) {
    uuid = packetReader.readUUID()
    username = packetReader.readString()
  }
  
  func handle(for server: Server) throws {
    server.connection.serverState = .play
  }
}

