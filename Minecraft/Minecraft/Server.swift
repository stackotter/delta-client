//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

// TODO: check protocol version and display warning before connecting if necessary
class Server: Hashable {
  var logger: Logger
  var client: Client
  var eventManager: EventManager
  
  // for events specific to this server (to keep events seperate when multiple servers are
  // being communicated with, like in the server list)
  var serverEventManager: EventManager
  
  var serverConnection: ServerConnection
  var info: ServerInfo
  
  var currentWorldName: Identifier?
  var worlds: [Identifier: World] = [:]
  var currentWorld: World? {
    if let worldName = currentWorldName {
      return worlds[worldName]
    }
    return nil
  }
  
  var player: Player
  
  var config: ServerConfig? = nil
  var state: ServerState = .idle
  
  // NOTE: maybe this could be consolidated to a struct if there are other play state kinda variables
  var downloadingTerrain = false
    
  // holds the packet handler for each state (packet handling is spread amongst them for readibility)
  var packetHandlers: [ServerConnection.ConnectionState: (PacketReader) -> Void] = [:]
  
  enum ServerState {
    case idle
    case connecting
    case status
    case login
    case play
    case disconnected
  }
  
  init(withInfo serverInfo: ServerInfo, eventManager: EventManager, client: Client) {
    self.client = client
    self.info = serverInfo
    self.eventManager = eventManager
    self.serverEventManager = EventManager()
    self.logger = Logger(for: type(of: self), desc: "\(info.host):\(info.port)")
    
    self.serverConnection = ServerConnection(host: info.host, port: info.port, eventManager: serverEventManager)
    
    // TODO: fix this once config is cleaned up
    self.player = Player(username: "stampy654")
    
    // create packet handlers
    self.packetHandlers[.login] = handleLoginPacket
    self.packetHandlers[.play] = handlePlayPacket
    
    self.serverConnection.registerPacketHandlers(handlers: packetHandlers)
    self.serverEventManager.registerEventHandler(handleEvents)
  }
  
  func handleEvents(_ event: EventManager.Event) {
    switch event {
      case .connectionClosed:
        state = .disconnected
      default:
        break
    }
  }
  
  // just a prototype for later
  func login() {
    serverConnection.restart()
    serverEventManager.registerOneTimeEventHandler({
      (event) in
      self.serverConnection.handshake(nextState: .login) {
        let loginStart = LoginStart(username: "stampy654")
        self.serverConnection.sendPacket(loginStart, callback: .contentProcessed({
          (error) in
          self.logger.debug("sent login start packet")
        }))
      }
    }, eventName: "connectionReady")
    serverConnection.start()
  }
  
  // TODO: handle rest of login packets
  // handles packets while in the login state
  func handleLoginPacket(packetReader: PacketReader) {
    var reader = packetReader // mutable copy of packetReader
    do {
      switch reader.packetId {
        case LoginDisconnect.id:
          let packet = try LoginDisconnect.from(&reader)!
          eventManager.triggerError(packet.reason)
          
        case 0x01:
          logger.debug("encryption request ignored")
        
        // TODO: do something with the uuid maybe?
        case LoginSuccess.id:
          let _ = try LoginSuccess.from(&reader)!
          serverConnection.state = .play
          
        case 0x03:
          logger.debug("set compression ignored")
          
        case 0x04:
          logger.debug("login plugin request ignored")
          
        default:
          return
      }
    } catch {
      eventManager.triggerError("failed to handle login packet with packet id: \(reader.packetId)")
    }
  }
  
  // handles packet while in the play state
  func handlePlayPacket(packetReader: PacketReader) {
    var reader = packetReader // mutable copy of packetReader
    logger.debug("play packet received with id: 0x\(String(packetReader.packetId, radix: 16))")
    do {
      switch reader.packetId {
        case SetDifficultyPacket.id:
          let _ = try SetDifficultyPacket.from(&reader)!
          
        case 0x17:
          logger.debug("plugin message ignored")
          
        case ChunkDataPacket.id:
          let packet = ChunkDataPacket.from(&reader)!
          currentWorld!.addChunk(data: packet.chunkData)
          
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
          let packet = try JoinGamePacket.from(&reader)!
          config = ServerConfig(worldCount: packet.worldCount, worldNames: packet.worldNames,
                                dimensionCodec: packet.dimensionCodec, maxPlayers: packet.maxPlayers,
                                viewDistance: packet.viewDistance, useReducedDebugInfo: packet.reducedDebugInfo,
                                enableRespawnScreen: packet.enableRespawnScreen)
          let worldConfig = WorldConfig(worldName: packet.worldName, dimension: packet.dimension,
                                        hashedSeed: packet.hashedSeed, isDebug: packet.isDebug, isFlat: packet.isFlat)
          let world = World(eventManager: serverEventManager, config: worldConfig)
          worlds[packet.worldName] = world
          currentWorldName = packet.worldName
          downloadingTerrain = true
          
        case PlayerAbilitiesPacket.id:
          let _ = PlayerAbilitiesPacket.from(&reader)!
          
        case HeldItemChangePacket.id:
          let _ = HeldItemChangePacket.from(&reader)!
          
        case UpdateViewPositionPacket.id:
          let packet = UpdateViewPositionPacket.from(&reader)!
          player.chunkPosition = packet.chunkPosition
          currentWorld!.unpackChunks(aroundChunk: packet.chunkPosition, withViewDistance: config!.viewDistance)
          
        case DeclareRecipesPacket.id:
          let _ = try DeclareRecipesPacket.from(&reader)!
          
        case TagsPacket.id:
          _ = try TagsPacket.from(&reader)
          
        default:
          return
      }
    } catch {
      logger.debug("\(error.localizedDescription)")
      eventManager.triggerError("failed to handle play packet with packet id: \(reader.packetId)")
    }
  }
  
  // Things so that SwiftUI ForEach loop works
  static func == (lhs: Server, rhs: Server) -> Bool {
    return (lhs.info.name == rhs.info.name && lhs.info.host == rhs.info.host && lhs.info.port == rhs.info.port)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(info.name)
    hasher.combine(info.host)
    hasher.combine(info.port)
  }
}
