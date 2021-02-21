//
//  PlayDisconnectPacket.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 9/2/21.
//

import Foundation
import os

struct PlayDisconnectPacket: ClientboundPacket {
  static let id: Int = 0x1a
  
  var reason: ChatComponent
  
  init(from packetReader: inout PacketReader) throws {
    reason = packetReader.readChat()
  }
  
  func handle(for server: Server) throws {
    Logger.log("disconnect reason: \(reason.toText())")
    server.eventManager.triggerError(reason.toText())
  }
}
