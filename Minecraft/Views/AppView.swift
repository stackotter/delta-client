//
//  AppView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

struct AppView: View {
  @ObservedObject var viewState: ViewState
  var game: Client
  var eventManager: EventManager
  
  init(game: Client, eventManager: EventManager) {
    self.game = game
    self.eventManager = eventManager
    
    self.viewState = ViewState(game: self.game, serverList: self.game.config.serverList!)
    
    self.eventManager.registerEventHandler(handleError, eventNames: ["error"])
  }
  
  var body: some View {
    if (viewState.isPlaying) {
      GameView(server: viewState.selectedServer!)
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
