//
//  MinecraftApp.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI

@main
struct MinecraftApp: App {
  var eventManager: EventManager
  var game: Game?
  
  var message: String = "loading.. (shouldn't take too long)"
  
  init() {
    eventManager = EventManager()
    do {
      game = try Game(eventManager: eventManager)
    } catch {
      message = "failed to initialise game: \(error.localizedDescription)"
    }
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
        if game != nil {
          AppView(game: game!, eventManager: eventManager)
        } else {
          Text(message)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
