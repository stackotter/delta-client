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
  
  var config: ServerConfig? = nil
  var state: ServerState = .idle
  
  enum ServerState {
    case idle
    case connecting
    case status
    case login
    case play
    case disconnected
  }
  
  init(name: String, host: String, port: Int, eventManager: EventManager) {
    self.name = name
    self.host = host
    self.port = port
    self.eventManager = eventManager
    self.serverEventManager = EventManager()
    self.logger = Logger(for: type(of: self), desc: "\(host):\(port)")
    self.serverConnection = ServerConnection(host: host, port: port, eventManager: serverEventManager)
    
    serverEventManager.registerEventHandler(handleEvents, eventNames: ["pingInfoReceived", "loginSuccess", "joinGame", "connectionClosed"])
    ping()
  }
  
  func handleEvents(_ event: EventManager.Event) {
    switch event {
      case let .pingInfoReceived(pingInfo):
        DispatchQueue.main.async {
          self.pingInfo = pingInfo
        }
        serverConnection.close()
      case .loginSuccess(packet: _):
        logger.debug("login success")
      case let .joinGame(packet: packet):
        state = .play
        config = ServerConfig(worldCount: packet.worldCount, worldNames: packet.worldNames,
                              dimensionCodec: packet.dimensionCodec, maxPlayers: packet.maxPlayers,
                              viewDistance: packet.viewDistance, useReducedDebugInfo: packet.reducedDebugInfo,
                              enableRespawnScreen: packet.enableRespawnScreen)
        let worldConfig = WorldConfig(worldName: packet.worldName, dimension: packet.dimension,
                                      hashedSeed: packet.hashedSeed, isDebug: packet.isDebug, isFlat: packet.isFlat)
        let world = World(eventManager: serverEventManager, config: worldConfig)
        worlds[packet.worldName] = world
        currentWorldName = packet.worldName
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
