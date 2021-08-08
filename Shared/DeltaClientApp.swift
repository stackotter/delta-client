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
        // TODO: handle asset downloading in delta core so that people using delta core can take advantage of it
        var stopwatch = Stopwatch(mode: .summary, name: "Startup")
        stopwatch.startMeasurement("Full startup")
        
        if !StorageManager.default.directoryExists(at: AssetManager.default.vanillaAssetsDirectory) {
          Self.loadingState.update(to: .loadingWithMessage("Downloading vanilla assets (might take a little while)"))
          try AssetManager.default.downloadVanillaAssets(forVersion: Constants.versionString)
        }
        
        if !StorageManager.default.directoryExists(at: AssetManager.default.pixlyzerDirectory) {
          Self.loadingState.update(to: .loadingWithMessage("Downloading pixlyzer data"))
          try AssetManager.default.downloadPixlyzerData(forVersion: Constants.versionString)
        }
        
        Self.loadingState.update(to: .loadingWithMessage("Loading block registry"))
        stopwatch.startMeasurement("Load block registry")
        let blockRegistry = try BlockRegistry.load(fromPixlyzerDataDirectory: AssetManager.default.pixlyzerDirectory)
        stopwatch.stopMeasurement("Load block registry")
        
        Self.loadingState.update(to: .loadingWithMessage("Loading resource pack"))
        stopwatch.startMeasurement("Load resource pack")
        let packCache = StorageManager.default.absoluteFromRelative("cache/vanilla.rpcache/")
        let cacheExists = StorageManager.default.directoryExists(at: packCache)
        let resourcePack = try ResourcePack.load(from: AssetManager.default.vanillaAssetsDirectory, blockRegistry: blockRegistry, cacheDirectory: cacheExists ? packCache : nil)
        stopwatch.stopMeasurement("Load resource pack")
        if !cacheExists {
          stopwatch.startMeasurement("Cache resource pack")
          do {
            try resourcePack.cache(to: packCache)
          } catch {
            log.warning("Failed to cache vanilla resource pack")
          }
          stopwatch.stopMeasurement("Cache resource pack")
        }
        
        // TODO: locale should be part of the resourcepack not the registry. Registries should always be the same (unlike resource pack which can be changed)
        stopwatch.startMeasurement("Load locale")
        let locale = try AssetManager.default.getLocale()
        stopwatch.stopMeasurement("Load locale")

        stopwatch.startMeasurement("Create registry")
        let registry = Registry(blockRegistry: blockRegistry, locale: locale)
        stopwatch.stopMeasurement("Create registry")
        
        if ConfigManager.default.config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }
        
        stopwatch.startMeasurement("Finish loading")
        Self.loadingState.update(to: .done(LoadedResources(resourcePack: resourcePack, registry: registry)))
        stopwatch.stopMeasurement("Finish loading")
        
        stopwatch.stopMeasurement("Full startup")
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
