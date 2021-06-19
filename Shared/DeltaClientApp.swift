//
//  DeltaClientApp.swift
//  Shared
//
//  Created by Rohan van Klinken on 16/6/21.
//

import SwiftUI
import DeltaCore

@main
struct DeltaClientApp: App {
  @ObservedObject var appState: StateWrapper<AppState>
  @ObservedObject var configManager: ConfigManager
  
  init() {
    appState = StateWrapper<AppState>(initial: .launch)
    
    // TODO: make storage manager a singleton
    let storageManager = try! StorageManager()
    
    // TODO: make config manager a singleton too if possible
    configManager = try! ConfigManager(storageManager: storageManager)
    
    appState.update(to: .serverList)
  }
  
  var body: some Scene {
    WindowGroup {
      RouterView()
        .frame(width: 800, height: 400)
        .environmentObject(appState)
        .environmentObject(configManager)
    }
  }
}
