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
  
  init() {
    Self.appState.update(to: .serverList)
  }
  
  var body: some Scene {
    WindowGroup {
      RouterView()
        .frame(width: 800, height: 400)
        .environmentObject(Self.modalState)
        .environmentObject(Self.appState)
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
  
  /// Logs a fatal error and then fatal errors.
  static func fatal(_ message: String) -> Never {
    log.critical(message)
    fatalError(message)
  }
}
