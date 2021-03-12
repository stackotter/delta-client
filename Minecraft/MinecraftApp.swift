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
  var dataManager: DataManager
  
  init() {
    eventManager = EventManager()
    dataManager = DataManager()
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
