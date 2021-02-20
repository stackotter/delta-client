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
  var server: Server
  var config: Config
  
  var eventManager: EventManager
  
  init(eventManager: EventManager, serverInfo: ServerInfo, config: Config) {
    self.eventManager = eventManager
    self.config = config
    
    self.server = Server(withInfo: serverInfo, eventManager: eventManager, clientConfig: config)
  }
  
  // TEMP
  func play() {
    server.login()
  }
}
