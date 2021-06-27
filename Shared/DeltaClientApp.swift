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
  @ObservedObject static var modalState = StateWrapper<ModalState>(initial: .none)
  @ObservedObject static var appState = StateWrapper<AppState>(initial: .launch)
  
  @ObservedObject var configManager: ConfigManager
  
  init() {
    
    // TODO: make storage manager a singleton
    let storageManager = try! DeltaCore.StorageManager()
    
    // TODO: make config manager a singleton too if possible
    configManager = try! ConfigManager(storageManager: storageManager)
    
    Self.appState.update(to: .serverList)
  }
  
  var body: some Scene {
    WindowGroup {
      RouterView()
        .frame(width: 800, height: 400)
        .environmentObject(Self.modalState)
        .environmentObject(Self.appState)
        .environmentObject(configManager)
    }
  }
  
  /// Display a dismissible warning.
  static func modalWarning(_ message: String) {
    log.warning("\(message)")
    Self.modalState.update(to: .warning(message))
  }
  
  /// Display a dismissible error and then transition to `safeState` if supplied.
  static func modalError(_ message: String, safeState: AppState? = nil) {
    log.error("\(message)")
    Self.modalState.update(to: .error(message, safeState: safeState))
  }
}
