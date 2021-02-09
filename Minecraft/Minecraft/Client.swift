//
//  Game.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation

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
  var server: Server? = nil
  var config: Config
  
  var eventManager: EventManager
  
  init(eventManager: EventManager, serverInfo: ServerInfo, config: Config) {
    self.eventManager = eventManager
    self.config = config
    
    self.server = Server(withInfo: serverInfo, eventManager: eventManager, client: self)
  }
  
  // TEMP
  func play() {
    server!.login()
  }
}
