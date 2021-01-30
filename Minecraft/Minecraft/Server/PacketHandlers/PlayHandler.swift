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
        case SetDifficultyPacket.id:
          let _ = SetDifficultyPacket.from(&reader)
          
        case ChunkDataPacket.id:
          let packet = ChunkDataPacket.from(&reader)
          server.currentWorld!.addChunk(data: packet.chunkData)
          
        // TODO: fix the chunk unpacking criteria
        //          if downloadingTerrain {
        //            let viewDiameter = config!.viewDistance * 2 + 1
        //            var numChunks = viewDiameter * viewDiameter
        //            // this could cause some issues but im assuming that's how this would work?
        //            if numChunks < 81 {
        //              numChunks = 81
        //            }
        //            if currentWorld!.packedChunks.count == numChunks {
        //              logger.log("view distance: \(self.config!.viewDistance)")
        //              currentWorld!.unpackChunks(aroundChunk: player.chunkPosition, withViewDistance: config!.viewDistance)
        //            }
        //          }
        
        case JoinGamePacket.id:
          let packet = try JoinGamePacket.from(&reader)
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
          let packet = PlayerAbilitiesPacket.from(&reader)
          server.player.flyingSpeed = packet.flyingSpeed
          server.player.fovModifier = packet.fovModifier
          server.player.updateFlags(to: packet.flags)
          
        case HeldItemChangePacket.id:
          let packet = HeldItemChangePacket.from(&reader)
          server.player.hotbarSlot = packet.slot
          
        case UpdateViewPositionPacket.id:
          let packet = UpdateViewPositionPacket.from(&reader)
          server.player.chunkPosition = packet.chunkPosition
          server.currentWorld!.unpackChunks(aroundChunk: packet.chunkPosition, withViewDistance: server.config!.viewDistance)
          
        case DeclareRecipesPacket.id:
          let packet = try DeclareRecipesPacket.from(&reader)
          client.recipeRegistry = packet.recipeRegistry
          
        case PluginMessagePacket.id:
          let packet = try PluginMessagePacket.from(&reader)
          logger.debug("plugin message received with channel: \(packet.pluginMessage.channel)")
          
        // TODO_LATER: figure out what this is needed for
        case TagsPacket.id:
          _ = TagsPacket.from(&reader)
          
        default:
          return
      }
    } catch {
      logger.debug("\(error.localizedDescription)")
      eventManager.triggerError("failed to handle play packet with packet id: \(reader.packetId)")
    }
  }
}
