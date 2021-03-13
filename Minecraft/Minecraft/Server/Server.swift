//
//  Server.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import Foundation
import os

class Server: Hashable {
  var managers: Managers
  
  var connection: ServerConnection
  var info: ServerInfo
  
  var currentWorldName: Identifier?
  var worlds: [Identifier: World] = [:]
  var currentWorld: World {
    if let worldName = currentWorldName {
      if let world = worlds[worldName] {
        return world
      }
    }
    return World(config: WorldConfig.createDefault(), managers: managers)
  }
  
  // TODO: maybe use a Registry object that stores all registries for neater code
  var recipeRegistry: RecipeRegistry = RecipeRegistry()
  var packetRegistry: PacketRegistry
  
  var player: Player
  
  var config: ServerConfig = ServerConfig.createDefault()
  var state: ServerState = .idle
  
  var difficulty: Difficulty = .normal
  var isDifficultyLocked: Bool = true
  
  var timeOfDay: Int64 = -1
  
  var tabList: TabList = TabList()
  
  enum ServerState {
    case idle
    case connecting
    case status
    case login
    case play
    case disconnected
  }
  
  init(withInfo serverInfo: ServerInfo, managers: Managers) {
    self.info = serverInfo
    self.managers = managers
    
    self.connection = ServerConnection(host: info.host, port: info.port, managers: self.managers)
    self.packetRegistry = PacketRegistry.createDefault()
    
    // TODO_LATER: fix this once config is cleaned up
    self.player = Player(username: "stampy876")
    
    self.managers.eventManager.registerEventHandler(handleEvents)
    self.connection.setHandler(handlePacket)
  }
  
  func handlePacket(_ packetReader: PacketReader, _ state: PacketState) {
    var reader = packetReader
    do {
      try packetRegistry.handlePacket(&reader, forServer: self, inState: state)
    } catch {
      Logger.debug("failed to handle status packet")
    }
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
    managers.eventManager.registerOneTimeEventHandler({
      (event) in
      self.connection.handshake(nextState: .login) {
        let loginStart = LoginStartPacket(username: self.player.username)
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
