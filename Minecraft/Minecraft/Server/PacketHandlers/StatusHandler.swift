//
//  StatusHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

enum StatusResponseError: LocalizedError {
  case invalidJSON
}

struct StatusHandler: PacketHandler {
  var serverPinger: ServerPinger
  var packetRegistry: PacketRegistry
  
  init(serverPinger: ServerPinger) {
    self.serverPinger = serverPinger
    self.packetRegistry = PacketRegistry.createDefault()
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    var reader = packetReader
    do {
      try packetRegistry.handlePacket(&reader, forServerPinger: serverPinger, inState: .status)
    } catch {
      Logger.debug(error.localizedDescription)
    }
  }
}
