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
  var game: Client?
  
  var message: String = "loading.. (shouldn't take too long)"
  
  init() {
    eventManager = EventManager()
    do {
      game = try Client(eventManager: eventManager)
    } catch {
      message = "failed to initialise game: \(error.localizedDescription)"
    }
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
        if game != nil {
          AppView(client: game!, eventManager: eventManager)
        } else {
          Text(message)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
