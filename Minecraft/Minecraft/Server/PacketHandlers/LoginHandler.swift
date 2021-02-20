//
//  LoginHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

// TODO_LATER: handle rest of login packets
struct LoginHandler: PacketHandler {
  var server: Server
  var eventManager: EventManager
  var packetRegistry: PacketRegistry
  
  init(server: Server) {
    self.server = server
    self.eventManager = self.server.eventManager
    self.packetRegistry = PacketRegistry.createDefault()
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    var reader = packetReader // mutable copy of packetReader
    do {
      try packetRegistry.handlePacket(&reader, forServer: server, inState: .login)
    } catch {
      Logger.debug(error.localizedDescription)
      eventManager.triggerError("failed to handle login packet with packet id: \(reader.packetId)")
    }
  }
}
