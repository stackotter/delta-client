//
//  LoginDisconnect.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginDisconnect: ClientboundPacket {
  static let id: Int = 0x00
  
  var reason: String
  
  init(fromReader packetReader: inout PacketReader) throws {
    reason = packetReader.readChat()
  }
  
  func handle(for client: Client) throws {
    client.eventManager.triggerError(reason)
  }
}
