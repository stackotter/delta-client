//
//  AppView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import SwiftUI

struct AppView: View {
  @ObservedObject var viewState: ViewState
  var client: Client
  var eventManager: EventManager
  
  init(client: Client, eventManager: EventManager) {
    self.client = client
    self.eventManager = eventManager
    
    do {
      let serverList = try self.client.config.getServerList(forClient: self.client)
      self.viewState = ViewState(game: self.client, serverList: serverList)
    } catch {
      self.viewState = ViewState(game: self.client)
      self.viewState.displayError(message: "failed to load server list")
    }
    
    
    self.eventManager.registerEventHandler(handleError, eventName: "error")
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
