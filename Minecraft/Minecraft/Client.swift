//
//  Game.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation
import os

enum ClientState {
  case idle
  case initialising
  case connecting
  case play
}

// pretty much the backend class for the whole game
class Client {
  var state: ClientState = .idle
  
  // TODO: maybe use a Registry object that stores all registries for neater code
  var recipeRegistry: RecipeRegistry = RecipeRegistry()
  var currentServer: Server? = nil
  var config: Config
  
  var eventManager: EventManager
  var logger: Logger
  
  init(eventManager: EventManager) throws {
    let minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
    self.eventManager = eventManager
    self.logger = Logger(for: type(of: self))
    
    self.config = Config(minecraftFolder: minecraftFolder, eventManager: eventManager)
  }
  
  func play(serverToPlay: Server) {
    currentServer = serverToPlay
    eventManager.link(with: self.currentServer!.serverEventManager)
  }
}
