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
  
  init() {
    eventManager = EventManager()
  }
  
  var body: some Scene {
    WindowGroup {
      Group {
        AppView(eventManager: eventManager)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
