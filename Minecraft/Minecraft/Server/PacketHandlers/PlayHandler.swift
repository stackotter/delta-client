//
//  PlayHandler.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 30/1/21.
//

import Foundation
import os

struct PlayHandler: PacketHandler {
  var client: Client
  var server: Server
  var logger: Logger
  var eventManager: EventManager
  
  init(server: Server) {
    self.logger = Logger(for: type(of: self))
    self.server = server
    self.client = self.server.client
    self.eventManager = self.server.eventManager
  }
  
  func handlePacket(_ packetReader: PacketReader) {
    var reader = packetReader // mutable copy of packetReader
    logger.debug("play packet received with id: 0x\(String(packetReader.packetId, radix: 16))")
    do {
      switch reader.packetId {
        case ServerDifficultyPacket.id:
          let _ = ServerDifficultyPacket(fromReader: &reader)
          
        case ChunkDataPacket.id:
          let packet = try ChunkDataPacket(fromReader: &reader)
          server.currentWorld!.addChunk(data: packet.chunk)
        
        case JoinGamePacket.id:
          let packet = try JoinGamePacket(fromReader: &reader)
          server.config = ServerConfig(worldCount: packet.worldCount, worldNames: packet.worldNames,
                                dimensionCodec: packet.dimensionCodec, maxPlayers: packet.maxPlayers,
                                viewDistance: packet.viewDistance, useReducedDebugInfo: packet.reducedDebugInfo,
                                enableRespawnScreen: packet.enableRespawnScreen)
          let worldConfig = WorldConfig(worldName: packet.worldName, dimension: packet.dimension,
                                        hashedSeed: packet.hashedSeed, isDebug: packet.isDebug, isFlat: packet.isFlat)
          let world = World(eventManager: eventManager, config: worldConfig)
          server.worlds[packet.worldName] = world
          server.currentWorldName = packet.worldName
          server.downloadingTerrain = true
          
        case PlayerAbilitiesPacket.id:
          let packet = PlayerAbilitiesPacket(fromReader: &reader)
          server.player.flyingSpeed = packet.flyingSpeed
          server.player.fovModifier = packet.fovModifier
          server.player.updateFlags(to: packet.flags)
          
        case HeldItemChangePacket.id:
          let packet = HeldItemChangePacket(fromReader: &reader)
          server.player.hotbarSlot = packet.slot
          
        case UpdateViewPositionPacket.id:
          let packet = UpdateViewPositionPacket(fromReader: &reader)
          server.player.chunkPosition = packet.chunkPosition
          // TODO_LATER: trigger world to recalculate which chunks should be rendered (if a circle is decided on for chunk rendering)
          
        case DeclareRecipesPacket.id:
          let packet = try DeclareRecipesPacket(fromReader: &reader)
          client.recipeRegistry = packet.recipeRegistry
          
        case PluginMessagePacket.id:
          let packet = try PluginMessagePacket(fromReader: &reader)
          logger.debug("plugin message received with channel: \(packet.pluginMessage.channel)")
          
        // TODO_LATER: figure out what this is needed for
        case TagsPacket.id:
          _ = TagsPacket(fromReader: &reader)
          
        default:
          return
      }
    } catch {
      logger.debug("\(error.localizedDescription)")
      eventManager.triggerError("failed to handle play packet with packet id: \(reader.packetId)")
    }
  }
}
