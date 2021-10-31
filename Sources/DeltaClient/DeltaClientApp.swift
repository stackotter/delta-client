import SwiftUI
import DeltaCore

struct DeltaClientApp: App {
  static var modalState = StateWrapper<ModalState>(initial: .none)
  static var appState = StateWrapper<AppState>(initial: .serverList)
  static var loadingState = StateWrapper<LoadingState>(initial: .loading)
  static var popupState = StateWrapper<PopupState>(initial: .hidden)
  
  /// Resource pack loaded on startup
  static var loadedResourcePack: LoadedResources?
  
  init() {
    let taskQueue = DispatchQueue(label: "dev.stackotter.delta-client.startupTasks")

    // Load the registry
    taskQueue.async {
      func updateLoadingMessage(_ message: String) {
        Self.loadingState.update(to: .loadingWithMessage(message))
        log.info(message)
      }
      
      do {
        if !StorageManager.default.directoryExists(at: StorageManager.default.vanillaAssetsDirectory) {
          updateLoadingMessage("Downloading vanilla assets (might take a little while)")
          try ResourcePack.downloadVanillaAssets(forVersion: Constants.versionString, to: StorageManager.default.vanillaAssetsDirectory)
        }
        
        updateLoadingMessage("Loading registries")
        try Registry.populateShared(StorageManager.default.registryDirectory)
        
        updateLoadingMessage("Loading resource pack")
        let packCache = StorageManager.Cache.vanilla.packCache
        let cacheExists = StorageManager.default.directoryExists(at: packCache)
        let resourcePack = try ResourcePack.load(from: StorageManager.default.vanillaAssetsDirectory, cacheDirectory: cacheExists ? packCache : nil)
        Self.loadedResourcePack = LoadedResources(resourcePack: resourcePack)
        
        if !cacheExists {
          do {
            try resourcePack.cache(to: packCache)
          } catch {
            log.warning("Failed to cache vanilla resource pack")
          }
        }
        
        if ConfigManager.default.config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }
        
        log.info("Done")
        Self.loadingState.update(to: .done(LoadedResources(resourcePack: resourcePack)))
      } catch {
        Self.fatal("Failed to load: \(error)")
      }
    }
  }
  
  var body: some Scene {
    WindowGroup {
      RouterView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(Self.popupState)
        .environmentObject(Self.modalState)
        .environmentObject(Self.appState)
        .environmentObject(Self.loadingState)
        .navigationTitle("Delta Client")
    }
    .commands {
      CommandGroup(after: .appSettings, addition: {
        Button("Preferences") {
          // Check if it makes sense to open settings right now, open it
          if case .none = Self.modalState.current, case .done(_) = Self.loadingState.current {
            switch Self.appState.current {
              case .serverList, .editServerList, .accounts, .login, .directConnect:
              Self.appState.update(to: .settings(.none))
              case .playServer(_), .settings:
                break
            }
          }
        }
        .keyboardShortcut(KeyboardShortcut(KeyEquivalent(","), modifiers: [.command]))
      })
    }
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
  
  /// Logs a fatal error and redirects to troubleshooting page.
  static func fatal(_ message: String) {
    log.critical(message)
    loadingState.update(to: .done(nil)) // If loading, removes loading screen
    Self.appState.update(to: .settings(.troubleshooting))
    popupState.update(to: .shown(PopupObject(title: "Fatal error",
                                             subtitle: message,
                                             image: Image(systemName: "exclamationmark.octagon"))
                                ))
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Auto dismissing popup after 3 seconds
      popupState.update(to: .hidden)
    }
  }
}
