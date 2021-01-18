//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

// TODO: check protocol version and display warning before connecting if necessary
class Server: Hashable, ObservableObject {
  var logger: Logger
  var client: Client
  var eventManager: EventManager
  
  // for events specific to this server (to keep events seperate when multiple servers are
  // being communicated with, like in the server list)
  var serverEventManager: EventManager
  
  var serverConnection: ServerConnection
  var name: String
  var host: String
  var port: Int
  
  // make this not an optional perhaps?
  @Published var pingInfo: PingInfo?
  
  var currentWorldName: Identifier?
  var worlds: [Identifier: World] = [:]
  var currentWorld: World? {
    if let worldName = currentWorldName {
      return worlds[worldName]
    }
    return nil
  }
  
  var config: ServerConfig? = nil
  var state: ServerState = .idle
  
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
  
  init(name: String, host: String, port: Int, eventManager: EventManager, client: Client) {
    self.client = client
    self.name = name
    self.host = host
    self.port = port
    self.eventManager = eventManager
    self.serverEventManager = EventManager()
    self.logger = Logger(for: type(of: self), desc: "\(host):\(port)")
    
    self.serverConnection = ServerConnection(host: host, port: port, eventManager: serverEventManager)
    
    // create packet handlers
    self.packetHandlers[.status] = handleStatusPacket
    self.packetHandlers[.login] = handleLoginPacket
    self.packetHandlers[.play] = handlePlayPacket
    
    self.serverConnection.registerPacketHandlers(handlers: packetHandlers)
    self.serverEventManager.registerEventHandler(handleEvents)
    
    // TODO_LATER probably shouldn't happen in init
    self.ping()
  }
  
  func handleEvents(_ event: EventManager.Event) {
    switch event {
      case .connectionClosed:
        state = .disconnected
      default:
        break
    }
  }
  
  func ping() {
    pingInfo = nil
    state = .status
    serverConnection.ping()
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
  
  // TODO: handle the rest of the status packets
  // handles packets received while in the status state
  func handleStatusPacket(packetReader: PacketReader) {
    do {
      switch (packetReader.packetId) {
        case StatusResponse.id:
          let packet = try StatusResponse.from(packetReader)!
          let json = packet.json
          
          do {
            let versionInfo = try json.getJSON(forKey: "version")
            let versionName = try versionInfo.getString(forKey: "name")
            let protocolVersion = try versionInfo.getInt(forKey: "protocol")
            
            let players = try json.getJSON(forKey: "players")
            let maxPlayers = try players.getInt(forKey: "max")
            let numPlayers = try players.getInt(forKey: "online")
            
            let pingInfo = PingInfo(versionName: versionName, protocolVersion: protocolVersion, maxPlayers: maxPlayers, numPlayers: numPlayers, description: "Ping Complete", modInfo: "")
            
            DispatchQueue.main.async {
              self.pingInfo = pingInfo
            }
            
            serverConnection.close()
          } catch {
            eventManager.triggerError("failed to handle status response json")
          }
        
        default:
          return
      }
    } catch {
      logger.debug("\(error.localizedDescription)")
    }
  }
  
  // TODO: handle rest of login packets
  // handles packets while in the login state
  func handleLoginPacket(packetReader: PacketReader) {
    do {
      switch (packetReader.packetId) {
        case LoginDisconnect.id:
          let packet = try LoginDisconnect.from(packetReader)!
          eventManager.triggerError(packet.reason)
          
        case 0x01:
          logger.debug("encryption request ignored")
        
        // TODO: do something with the uuid maybe?
        case LoginSuccess.id:
          let _ = try LoginSuccess.from(packetReader)!
          serverConnection.state = .play
          
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
  
  // handles packet while in the play state
  func handlePlayPacket(packetReader: PacketReader) {
    logger.debug("play packet received with id: 0x\(String(packetReader.packetId, radix: 16))")
    do {
      switch (packetReader.packetId) {
        case SetDifficultyPacket.id:
          let _ = try SetDifficultyPacket.from(packetReader)!
          
        case 0x17:
          logger.debug("plugin message ignored")
          
        case ChunkDataPacket.id:
          let packet = ChunkDataPacket.from(packetReader)!
          worlds[currentWorldName!]!.addChunk(data: packet.chunkData)
          
        case JoinGamePacket.id:
          let packet = try JoinGamePacket.from(packetReader)!
          config = ServerConfig(worldCount: packet.worldCount, worldNames: packet.worldNames,
                                dimensionCodec: packet.dimensionCodec, maxPlayers: packet.maxPlayers,
                                viewDistance: packet.viewDistance, useReducedDebugInfo: packet.reducedDebugInfo,
                                enableRespawnScreen: packet.enableRespawnScreen)
          let worldConfig = WorldConfig(worldName: packet.worldName, dimension: packet.dimension,
                                        hashedSeed: packet.hashedSeed, isDebug: packet.isDebug, isFlat: packet.isFlat)
          let world = World(eventManager: serverEventManager, config: worldConfig)
          worlds[packet.worldName] = world
          currentWorldName = packet.worldName
          
        case PlayerAbilitiesPacket.id:
          let _ = PlayerAbilitiesPacket.from(packetReader)!
          
        case HeldItemChangePacket.id:
          let _ = HeldItemChangePacket.from(packetReader)!
          
        case UpdateViewPositionPacket.id:
          let packet = UpdateViewPositionPacket.from(packetReader)!
          currentWorld!.unpackChunks(aroundChunk: packet.chunkPosition, withRadius: config!.viewDistance)
          
        case DeclareRecipesPacket.id:
          let _ = try DeclareRecipesPacket.from(packetReader)!
          
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
  
  // Things so that SwiftUI ForEach loop works
  static func == (lhs: Server, rhs: Server) -> Bool {
    return (lhs.name == rhs.name && lhs.host == rhs.host && lhs.port == rhs.port)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(host)
    hasher.combine(port)
  }
}
