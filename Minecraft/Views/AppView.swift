//
//  AppView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

struct AppView: View {
  @ObservedObject var viewState: ViewState
  var eventManager: EventManager
  var config: Config
  
  init(eventManager: EventManager) {
    self.eventManager = eventManager
    let configManager = ConfigManager(eventManager: self.eventManager)
    self.config = configManager.getCurrentConfig()
    
    let serverList = self.config.serverList
    serverList.refresh()
    self.viewState = ViewState(serverList: serverList)
    
    self.eventManager.registerEventHandler(handleError, eventName: "error")
  }
  
  var body: some View {
    if (viewState.isPlaying) {
      GameView(serverInfo: viewState.selectedServerInfo!, config: config, eventManager: eventManager)
    }
    else if(viewState.isErrored) {
      ErrorView(viewState: viewState)
    }
    else {
      ServerListView(viewState: viewState)
    }
  }
  
  func handleError(_ event: EventManager.Event) {
    switch event {
      case let .error(message):
        DispatchQueue.main.sync {
          viewState.displayError(message: message)
        }
      default:
        break
    }
  }
}
