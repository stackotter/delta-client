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
          let packet = try SetDifficultyPacket.from(packetReader)!
          eventManager.triggerEvent(.setDifficulty(difficulty: packet.difficulty))
        case 0x17:
          logger.debug("plugin message ignored")
        case 0x20:
          let packet = ChunkDataPacket.from(packetReader)!
          eventManager.triggerEvent(.chunkData(chunkData: packet.chunkData))
        case 0x24:
          eventManager.triggerEvent(.joinGame(packet: try JoinGamePacket.from(packetReader)!))
        case 0x30:
          eventManager.triggerEvent(.playerAbilities(packet: PlayerAbilitiesPacket.from(packetReader)!))
        case 0x3f:
          let packet = HeldItemChangePacket.from(packetReader)!
          eventManager.triggerEvent(.hotbarSlotChange(slot: Int(packet.slot)))
        case 0x40:
          let packet = UpdateViewPositionPacket.from(packetReader)!
          eventManager.triggerEvent(.updateViewPosition(currentChunk: packet.chunkPosition))
        case 0x5a:
          let packet = try DeclareRecipesPacket.from(packetReader)!
          eventManager.triggerEvent(.declareRecipes(recipeRegistry: packet.recipeRegistry))
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
}
