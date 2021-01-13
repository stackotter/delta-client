//
//  PlayHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation
import os

struct PlayHandler: PacketHandler {
  var logger: Logger
  var eventManager: EventManager
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    self.logger = Logger(for: type(of: self))
  }
  
  func handlePacket(packetReader: PacketReader) {
    logger.debug("play packet received with id: 0x\(String(packetReader.packetId, radix: 16))")
    do {
      switch (packetReader.packetId) {
        case 0x0d:
          handle(try SetDifficultyPacket.from(packetReader)!)
        case 0x17:
          logger.debug("plugin message ignored")
        case 0x20:
          _ = try ChunkDataPacket.from(packetReader)
        case 0x24:
          eventManager.triggerEvent(.joinGame(packet: try JoinGamePacket.from(packetReader)!))
        case 0x30:
          eventManager.triggerEvent(.playerAbilities(packet: PlayerAbilitiesPacket.from(packetReader)!))
        case 0x3f:
          handle(HeldItemChangePacket.from(packetReader)!)
        case 0x5a:
          handle(try DeclareRecipesPacket.from(packetReader)!)
        case 0x5b:
          _ = try TagsPacket.from(packetReader)
        default:
          return
      }
    } catch {
      logger.debug("\(error.localizedDescription)")
      eventManager.triggerError("failed to handle play packet with packet id: \(packetReader.packetId)")
    }
  }
  
  func handle(_ packet: SetDifficultyPacket) {
    logger.debug("difficulty: \(String(reflecting: packet.difficulty))")
    eventManager.triggerEvent(.setDifficulty(difficulty: packet.difficulty))
  }
  
  func handle(_ packet: HeldItemChangePacket) {
    eventManager.triggerEvent(.hotbarSlotChange(slot: Int(packet.slot)))
  }
  
  func handle(_ packet: DeclareRecipesPacket) {
    eventManager.triggerEvent(.declareRecipes(recipeRegistry: packet.recipeRegistry))
  }
}
