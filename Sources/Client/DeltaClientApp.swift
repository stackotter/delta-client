import SwiftUI
import DeltaCore

/// The entry-point for Delta Client.
struct DeltaClientApp: App {
  // MARK: - Global state
  
  // These are static so that they can be used from static functions like `modalError`. And because otherwise they can't be captured by the async startup task.
  private static var modalState = StateWrapper<ModalState>(initial: .none)
  private static var appState = StateWrapper<AppState>(initial: .serverList)
  private static var startupState = StateWrapper<StartupState>(initial: .loading)
  private static var loadingState = StateWrapper<LoadingState>(initial: .none)
  private static var popupState = StateWrapper<PopupState>(initial: .hidden)
  public static var pluginEnvironment = PluginEnvironment()
  
  
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

    // Load plugins, registries and resources
    taskQueue.async {
      func updateLoadingMessage(_ message: String) {
        Self.startupState.update(to: .loadingWithMessage(message))
        log.info(message)
      }
      
      do {
        // Load plugins first
        updateLoadingMessage("Loading plugins")
        do {
          try Self.pluginEnvironment.loadPlugins(
            from: StorageManager.default.pluginsDirectory,
            excluding: ConfigManager.default.config.unloadedPlugins)
          for (bundle, error) in Self.pluginEnvironment.errors {
            log.error("Error occured when loading plugin '\(bundle)': \(error.localizedDescription)")
          }
        } catch {
          Self.modalError("Error occurred during plugin loading, no plugins will be available: \(error)")
        }
        
        // Download vanilla assets if they haven't already been downloaded
        if !StorageManager.default.directoryExists(at: StorageManager.default.vanillaAssetsDirectory) {
          updateLoadingMessage("Downloading vanilla assets (might take a little while)")
          try ResourcePack.downloadVanillaAssets(forVersion: Constants.versionString, to: StorageManager.default.vanillaAssetsDirectory)
        }
        
        // Load registries
        updateLoadingMessage("Loading registries")
        try Registry.populateShared(StorageManager.default.registryDirectory)
        
        // Load resource pack and cache it if necessary
        updateLoadingMessage("Loading resource pack")
        let packCache = StorageManager.default.cacheDirectory.appendingPathComponent("vanilla.rpcache/")
        let cacheExists = StorageManager.default.directoryExists(at: packCache)
        let resourcePack = try ResourcePack.load(from: StorageManager.default.vanillaAssetsDirectory, cacheDirectory: cacheExists ? packCache : nil)
        
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
        log.info("Done")
        Self.startupState.update(to: .done(LoadedResources(resourcePack: resourcePack)))
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
        .environmentObject(Self.startupState)
        .environmentObject(Self.loadingState)
        .environmentObject(Self.pluginEnvironment)
        .navigationTitle("Delta Client")
    }
    .commands {
      // Add preferences menu item and shortcut (cmd+,)
      CommandGroup(after: .appSettings, addition: {
        Button("Preferences") {
          // Check if it makes sense to be able to open settings right now
          if case .none = Self.modalState.current, case .done(_) = Self.startupState.current {
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
    startupState.update(to: .fatalError)
    popupState.update(to: .shown(PopupObject(title: "Fatal error",
                                             subtitle: message,
                                             image: Image(systemName: "exclamationmark.octagon"))
                                ))
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Auto dismissing popup after 3 seconds
      popupState.update(to: .hidden)
    }
  }
}
