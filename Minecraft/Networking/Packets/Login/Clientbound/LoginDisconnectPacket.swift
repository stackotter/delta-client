//
//  LoginDisconnect.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginDisconnectPacket: ClientboundPacket {
  static let id: Int = 0x00
  
  var reason: ChatComponent
  
  init(fromReader packetReader: inout PacketReader) throws {
    reason = packetReader.readChat()
  }
  
  func handle(for server: Server) throws {
    server.eventManager.triggerError(reason.toText())
  }
}
