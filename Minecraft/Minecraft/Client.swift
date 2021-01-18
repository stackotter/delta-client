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
  
  // IDEA: maybe use a Registry object that stores all registries for neater code
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
    
    // TODO_LATER: move this to the registry object talked about in that IDEA comment somewhere up there
    // TODO: handle declare recipes somewhere here again, might just hand a reference to client to server
//    eventManager.registerEventHandler(handleEvent, eventName: "declareRecipes")
  }
}
