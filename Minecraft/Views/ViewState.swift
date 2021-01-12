//
//  ViewState.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 26/12/20.
//

import Foundation

class ViewState: ObservableObject {
  @Published var isPlaying = false
  @Published var selectedServer: Server?
  @Published var isErrored = false
  @Published var errorMessage: String?
  
  @Published var serverList: ServerList
  
  var game: Game
  
  init(game: Game) {
    self.serverList = ServerList()
    self.game = game
  }
  
  init(game: Game, serverList: ServerList) {
    self.serverList = serverList
    self.game = game
  }
  
  func updateServerList(newServerList: ServerList) {
    serverList = newServerList
  }
  
  func playServer(server: Server) {
    isPlaying = true
    selectedServer = server
    isErrored = false
    errorMessage = nil
    
    DispatchQueue.main.async {
      self.game.play(serverToPlay: server)
    }
  }
  
  func displayError(message: String) {
    isErrored = true
    isPlaying = false
    errorMessage = message
    selectedServer = nil
  }
}
