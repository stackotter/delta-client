//
//  LoginHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation
import os

struct LoginHandler: PacketHandler {
  var logger: Logger
  var eventManager: EventManager
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    self.logger = Logger(for: type(of: self))
  }
  
  func handlePacket(packetReader: PacketReader) {
    do {
      switch (packetReader.packetId) {
        case 0x00:
          handle(try LoginDisconnect.from(packetReader)!)
        case 0x01:
          logger.debug("encryption request ignored")
        case 0x02:
          let packet = try LoginSuccess.from(packetReader)!
          eventManager.triggerEvent(.loginSuccess(packet: packet))
        case 0x03:
          logger.debug("set compression ignored")
        case 0x04:
          logger.debug("login plugin request ignored")
        default:
          return
      }
    } catch {
      eventManager.triggerError("failed to handle login packet with packet id: \(packetReader.packetId)")
    }
  }
  
  func handle(_ packet: LoginDisconnect) {
    eventManager.triggerEvent(.loginDisconnect(reason: packet.reason))
  }
}
