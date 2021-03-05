//
//  ViewState.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 26/12/20.
//

import Foundation

class ViewState: ObservableObject {
  @Published var isPlaying = false
  @Published var playingCommands = false
  @Published var selectedServerInfo: ServerInfo?
  @Published var isErrored = false
  @Published var errorMessage: String?
  
  @Published var serverList: ServerList
  
  init() {
    self.serverList = ServerList()
  }
  
  init(serverList: ServerList) {
    self.serverList = serverList
  }
  
  func updateServerList(newServerList: ServerList) {
    serverList = newServerList
  }
  
  func playServer(withInfo info: ServerInfo, withCommands: Bool) {
    isPlaying = true
    playingCommands = withCommands
    selectedServerInfo = info
    isErrored = false
    errorMessage = nil
  }
  
  func displayError(message: String) {
    isErrored = true
    isPlaying = false
    errorMessage = message
    selectedServerInfo = nil
  }
}
