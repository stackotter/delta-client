//
//  PlayHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

// TODO: clean up networking and move everything to a single PacketHandler that uses the PacketRegistry
struct PlayHandler: PacketHandler {
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
      try packetRegistry.handlePacket(&reader, forServer: server, inState: .play)
    } catch {
      Logger.debug(error.localizedDescription)
      eventManager.triggerError("failed to handle play packet with packet id: \(reader.packetId)")
    }
  }
}
