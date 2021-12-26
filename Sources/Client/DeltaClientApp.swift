import SwiftUI
import DeltaCore

/// The entry-point for Delta Client.
struct DeltaClientApp: App {
  // MARK: Global state
  // These are static so that they can be used from static functions like `modalError`. And because otherwise they can't be captured by the async startup task.
  
  @ObservedObject private static var modalState = StateWrapper<ModalState>(initial: .none)
  @ObservedObject private static var appState = StateWrapper<AppState>(initial: .serverList)
  @ObservedObject private static var loadingState = StateWrapper<LoadingState>(initial: .loading)
  
  @ObservedObject public static var pluginEnvironment = PluginEnvironment()
  
  // MARK: Init
  
  init() {
    let taskQueue = DispatchQueue(label: "dev.stackotter.delta-client.startupTasks")
    
    // Process command line arguments
    let arguments = CommandLineArguments.parseOrExit()
    
    if arguments.help {
      print(CommandLineArguments.helpMessage())
      Foundation.exit(0)
    }
    
    if let pluginsDirectory = arguments.pluginsDirectory {
      StorageManager.default.pluginsDirectory = pluginsDirectory
    }
    
    DiscordManager.shared.updateRichPresence(to: .menu)

    // Load plugins, registries and resources
    taskQueue.async {
      func updateLoadingMessage(_ message: String) {
        Self.loadingState.update(to: .loadingWithMessage(message))
        log.info(message)
      }
      
      do {
        let start = CFAbsoluteTimeGetCurrent()
        
        // Load plugins first
        updateLoadingMessage("Loading plugins")
        do {
          try Self.pluginEnvironment.loadPlugins(
            from: StorageManager.default.pluginsDirectory,
            excluding: ConfigManager.default.config.unloadedPlugins)
          for (bundle, error) in Self.pluginEnvironment.errors {
            log.error("Error occured when loading plugin '\(bundle)': \(error)")
          }
        } catch {
          Self.modalError("Error occurred during plugin loading, no plugins will be available: \(error.localizedDescription)")
        }
        
        // Download vanilla assets if they haven't already been downloaded
        if !StorageManager.default.directoryExists(at: StorageManager.default.vanillaAssetsDirectory) {
          updateLoadingMessage("Downloading vanilla assets (might take a little while)")
          try ResourcePack.downloadVanillaAssets(forVersion: Constants.versionString, to: StorageManager.default.vanillaAssetsDirectory)
        }
        
        // Load registries
        updateLoadingMessage("Loading registries")
        try RegistryStore.populateShared(StorageManager.default.registryDirectory)
        
        // Load resource pack and cache it if necessary
        updateLoadingMessage("Loading resource pack")
        let packCache = StorageManager.default.cacheDirectory.appendingPathComponent("vanilla.rpcache/")
        var cacheExists = StorageManager.default.directoryExists(at: packCache)
        let resourcePack = try ResourcePack.load(from: StorageManager.default.vanillaAssetsDirectory, cacheDirectory: cacheExists ? packCache : nil)
        cacheExists = StorageManager.default.directoryExists(at: packCache)
        if !cacheExists {
          do {
            try resourcePack.cache(to: packCache)
          } catch {
            log.warning("Failed to cache vanilla resource pack")
          }
        }
        
        // Get user to login if they haven't already
        if ConfigManager.default.config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }
        
        // Finish loading
        let elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000
        let elapsedString = String(format: "%.2f", elapsedMilliseconds)
        log.info("Done (\(elapsedString)ms)")
        Self.loadingState.update(to: .done(LoadedResources(resourcePack: resourcePack)))
      } catch {
        Self.loadingState.update(to: .error("Failed to load: \(error.localizedDescription)"))
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
        .environmentObject(Self.pluginEnvironment)
        .navigationTitle("Delta Client")
    }
    .commands {
      // Add preferences menu item and shortcut (cmd+,)
      CommandGroup(after: .appSettings, addition: {
        Button("Preferences") {
          // Check if it makes sense to be able to open settings right now
          if case .none = Self.modalState.current, case .done(_) = Self.loadingState.current {
            switch Self.appState.current {
              case .serverList, .editServerList, .accounts, .login, .directConnect:
                Self.appState.update(to: .settings)
              case .playServer(_), .settings, .fatalError(_):
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
  
  /// Logs a fatal error and then fatal errors.
  static func fatal(_ message: String) -> Never {
    log.critical(message)
    fatalError(message)
  }
}
