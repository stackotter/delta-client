//
//  AppView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

struct AppView: View {
  @ObservedObject var state: ViewState
  var eventManager: EventManager
  var managers: Managers
  
  var config: Config
  
  init(managers: Managers) {
    self.managers = managers
    self.eventManager = self.managers.eventManager
    
    let configManager = ConfigManager(eventManager: self.eventManager)
    self.config = configManager.getCurrentConfig()
    
    let serverList = self.config.serverList
    serverList.refresh()
    self.state = ViewState(initialState: .serverList(serverList: serverList))
  }
  
  var body: some View {
    switch state.state {
      case .playing(let withRendering, let serverInfo):
        if withRendering {
          GameRenderView(serverInfo: serverInfo, config: config, managers: managers)
        } else {
          GameCommandView(serverInfo: serverInfo, config: config, managers: managers)
        }
      case .serverList(let serverList):
        ServerListView(viewState: state, serverList: serverList)
    }
  }
}
