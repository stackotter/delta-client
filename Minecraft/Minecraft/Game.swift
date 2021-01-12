//
//  Game.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation
import os

enum GameState {
  case idle
  case initialisation
  case connection
  case play
}

class Game {
  var state: GameState = .idle
  
  // IDEA: maybe use a Registry object that stores all registries for neater code
  var recipeRegistry: RecipeRegistry = RecipeRegistry()
  var server: Server? = nil
  var config: Config
  
  var eventManager: EventManager
  var logger: Logger
  
  init(eventManager: EventManager) throws {
    let minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
    self.eventManager = eventManager
    self.logger = Logger(for: type(of: self))
    
    do {
      self.config = try Config(minecraftFolder: minecraftFolder, eventManager: eventManager)
    } catch {
      logger.debug("failed to load config: \(error.localizedDescription)")
      throw error
    }
    
    registerEventHandler()
  }
  
  func play(serverToPlay: Server) {
    server = serverToPlay
    server!.serverEventManager.registerEventHandler(handleEvent, eventNames: ["declareRecipes"])
  }
  
  func registerEventHandler() {
    eventManager.registerEventHandler(handleEvent, eventNames: ["declareRecipes"])
  }
  
  func handleEvent(event: EventManager.Event) {
    switch event {
      case let .declareRecipes(recipeRegistry: recipeRegistry):
        self.recipeRegistry = recipeRegistry
      default:
        break
    }
  }
}
