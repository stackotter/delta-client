//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

class Server: Hashable {
  var eventManager: EventManager
  var clientConfig: Config
  
  var connection: ServerConnection
  var info: ServerInfo
  
  var currentWorldName: Identifier?
  var worlds: [Identifier: World] = [:]
  var currentWorld: World? {
    if let worldName = currentWorldName {
      return worlds[worldName]
    }
    return nil
  }
  
  // TODO: maybe use a Registry object that stores all registries for neater code
  var recipeRegistry: RecipeRegistry = RecipeRegistry()
  
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
  
  init(withInfo serverInfo: ServerInfo, eventManager: EventManager, clientConfig: Config) {
    self.info = serverInfo
    self.eventManager = eventManager
    self.clientConfig = clientConfig
    
    self.connection = ServerConnection(host: info.host, port: info.port, eventManager: self.eventManager, locale: self.clientConfig.locale)
    
    // TODO: fix this once config is cleaned up
    self.player = Player(username: "stampy654")
    
    // create packet handlers
    self.packetHandlers[.login] = LoginHandler(server: self)
    self.packetHandlers[.play] = PlayHandler(server: self)
    
    self.connection.registerPacketHandlers(handlers: packetHandlers)
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
  
  func sendPacket(_ packet: ServerboundPacket) {
    connection.sendPacket(packet)
  }
  
  // just a prototype for later
  func login() {
    connection.restart()
    eventManager.registerOneTimeEventHandler({
      (event) in
      self.connection.handshake(nextState: .login) {
        let loginStart = LoginStart(username: "stampy654")
        self.connection.sendPacket(loginStart, callback: .contentProcessed({
          (error) in
          Logger.debug("sent login start packet")
        }))
      }
    }, eventName: "connectionReady")
    connection.start()
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
