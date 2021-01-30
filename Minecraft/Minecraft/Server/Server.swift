//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

class Server: Hashable {
  var logger: Logger
  var client: Client
  var eventManager: EventManager
  
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
  var packetHandlers: [ServerConnection.ConnectionState: PacketHandler] = [:]
  
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
    self.logger = Logger(for: type(of: self), desc: "\(info.host):\(info.port)")
    
    self.serverConnection = ServerConnection(host: info.host, port: info.port, eventManager: self.eventManager)
    
    // TODO: fix this once config is cleaned up
    self.player = Player(username: "stampy654")
    
    // create packet handlers
    self.packetHandlers[.login] = LoginHandler(server: self)
    self.packetHandlers[.play] = PlayHandler(server: self)
    
    self.serverConnection.registerPacketHandlers(handlers: packetHandlers)
    self.eventManager.registerEventHandler(handleEvents)
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
    eventManager.registerOneTimeEventHandler({
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
    return (lhs.info.name == rhs.info.name && lhs.info.host == rhs.info.host && lhs.info.port == rhs.info.port)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(info.name)
    hasher.combine(info.host)
    hasher.combine(info.port)
  }
}
