//
//  LoginHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

// TODO: handle rest of login packets
struct LoginHandler: PacketHandler {
  var client: Client
  var server: Server
  var eventManager: EventManager
  
  init(server: Server) {
    self.server = server
    self.client = self.server.client
    self.eventManager = self.server.eventManager
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    var reader = packetReader // mutable copy of packetReader
    do {
      switch reader.packetId {
        case LoginDisconnect.id:
          let packet = try LoginDisconnect(fromReader: &reader)
          eventManager.triggerError(packet.reason)
          
        case 0x01:
          Logger.debug("encryption request ignored")
          
        // TODO: do something with the uuid maybe?
        case LoginSuccess.id:
          let _ = LoginSuccess(fromReader: &reader)
          server.serverConnection.state = .play
          
        case 0x03:
          Logger.debug("set compression ignored")
          
        case 0x04:
          Logger.debug("login plugin request ignored")
          
        default:
          return
      }
    } catch {
      eventManager.triggerError("failed to handle login packet with packet id: \(reader.packetId)")
    }
  }
}
