//
//  MinecraftApp.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI
import os

@main
struct MinecraftApp: App {
  @ObservedObject var state = AppState(initialState: .loading(message: "loading game.."))
  let eventManager = EventManager()
  
  init() {
    // register event handler
    self.eventManager.registerEventHandler(handleEvent)
    
    // run app startup sequence
    let thread = DispatchQueue(label: "startup")
    let startupSequence = StartupSequence(eventManager: self.eventManager)
    thread.async {
      do {
        try startupSequence.run()
      } catch {
        startupSequence.eventManager.triggerError("failed to complete startup")
      }
    }
  }
  
  func handleEvent(_ event: EventManager.Event) {
    switch event {
      case .loadingScreenMessage(let message):
        Logger.debug(message)
        state.displayLoadingScreenMessage(message)
      case .loadingComplete(let managers):
        state.finishLoading(withManagers: managers)
      case .error(let message):
        Logger.error(message)
        state.displayError(message)
      default:
        break
    }
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
        switch state.state {
          case .error(let message):
            Text(message)
          case .loading(let message):
            Text(message)
          case .loaded(let managers):
            AppView(managers: managers)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
