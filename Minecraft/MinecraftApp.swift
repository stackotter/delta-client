//
//  MinecraftApp.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI

@main
struct MinecraftApp: App {
  let minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
  var config: Config?
  var eventManager: EventManager
  @ObservedObject var viewState: ViewState
  
  init() {
    eventManager = EventManager()
    guard let config = try? Config(minecraftFolder: minecraftFolder, eventManager: eventManager) else {
      viewState = ViewState(serverList: ServerList())
      viewState.displayError(message: "failed to load config")
      return
    }
    
    self.config = config
    viewState = ViewState(serverList: self.config!.serverList!)
    
    eventManager.registerEventHandler(handleError, eventNames: ["error"])
  }
  
  func handleError(_ event: EventManager.Event) {
    switch event {
      case let .error(message):
        viewState.displayError(message: message)
      default:
        break
    }
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
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
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
