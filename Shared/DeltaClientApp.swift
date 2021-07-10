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
  @ObservedObject static var appState = StateWrapper<AppState>(initial: .serverList)
  @ObservedObject static var loadingState = StateWrapper<LoadingState>(initial: .loading)
  
  init() {
    let taskQueue = DispatchQueue(label: "dev.stackotter.delta-client.startupTasks")

    // Load the registry
    taskQueue.async {
      do {
        if !StorageManager.default.directoryExists(at: AssetManager.default.vanillaAssetsDirectory) {
          Self.loadingState.update(to: .loadingWithMessage("Downloading vanilla assets (might take a little while)"))
          try AssetManager.default.downloadVanillaAssets(forVersion: Constants.versionString)
        }
        
        if !StorageManager.default.directoryExists(at: AssetManager.default.pixlyzerDirectory) {
          Self.loadingState.update(to: .loadingWithMessage("Downloading pixlyzer data"))
          try AssetManager.default.downloadPixlyzerData(forVersion: Constants.versionString)
        }
        
        Self.loadingState.update(to: .loadingWithMessage("Loading block texture palette"))
        let texturePalette = try AssetManager.default.getBlockTexturePalette()

        let pixlyzerData = AssetManager.default.pixlyzerDirectory.appendingPathComponent("blocks.min.json")

        Self.loadingState.update(to: .loadingWithMessage("Loading block models"))
        let blockModels = AssetManager.default.vanillaAssetsDirectory.appendingPathComponent("minecraft/models/block")
        let blockRegistry = try BlockRegistry.parse(
          fromPixlyzerDataAt: pixlyzerData,
          withBlockModelDirectoryAt: blockModels,
          andTexturesFrom: texturePalette)
        
        let locale = try AssetManager.default.getLocale()

        let registry = Registry(blockRegistry: blockRegistry, locale: locale)
        
        if ConfigManager.default.config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }
        
        Self.loadingState.update(to: .done(registry))
      } catch {
        Self.loadingState.update(to: .error("Failed to create registry: \(error)"))
      }
    }
  }
  
  var body: some Scene {
    WindowGroup {
      RouterView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(Self.modalState)
        .environmentObject(Self.appState)
        .environmentObject(Self.loadingState)
    }
    
    #if os(macOS)
    Settings {
      SettingsView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    #endif
  }
  
  /// Display a dismissible warning.
  static func modalWarning(_ message: String) {
    log.warning("\(message)")
    Self.modalState.update(to: .warning(message))
  }
  
  /// Display a dismissible error and then transition to `safeState` if supplied.
  static func modalError(_ message: String, safeState: AppState? = nil) {
    Self.modalState.update(to: .error(message, safeState: safeState))
  }
  
  /// Logs a fatal error and then fatal errors.
  static func fatal(_ message: String) -> Never {
    log.critical(message)
    fatalError(message)
  }
}
