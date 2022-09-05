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
    
    Self.handleCommandLineArguments()
    
    DiscordManager.shared.updateRichPresence(to: .menu)

    // Load plugins, registries and resources
    taskQueue.async {
      var startupProgress = TaskProgress<StartupStep>()
      
      func updateLoadingState(step: StartupStep, message: String? = nil, taskProgress: Double = 0) {
        let secretMessages: [String] = [
          "Frying eggs",
          "Baking cookies",
          "Planting trees",
          "Filling up oceans",
          "Painting clouds",
          "Dreaming of ancient worlds"
        ]
        let shouldShowSecretMessage = Double.random(in: 0...1) <= 0.005
        
        let loadingMessage: String
        if shouldShowSecretMessage {
          loadingMessage = secretMessages.randomElement() ?? step.message
        } else if let message = message {
          loadingMessage = message
        } else {
          loadingMessage = step.message
        }
        
        if startupProgress.currentStep != step {
          log.info(step.message)
        }
        
        startupProgress.update(to: step, stepProgress: taskProgress)
        
        Self.loadingState.update(to: .loadingWithMessage(
          loadingMessage,
          progress: startupProgress.progress
        ))
      }
      
      do {
        let start = CFAbsoluteTimeGetCurrent()
        
        // Refresh accounts if they're close to expiring (expire in the next 3 hours)
        for account in ConfigManager.default.config.accounts.values {
          guard let expiry = account.online?.accessToken.expiry else {
            continue
          }
          
          if expiry - Int(CFAbsoluteTimeGetCurrent()) < 10800 {
            Task {
              var account = account
              try? await account.refreshIfExpired(withClientToken: ConfigManager.default.config.clientToken)
              ConfigManager.default.addAccount(account)
            }
          }
        }
        
        // Load plugins first
        updateLoadingState(step: .loadPlugins)
        do {
          try Self.pluginEnvironment.loadPlugins(
            from: StorageManager.default.pluginsDirectory,
            excluding: ConfigManager.default.config.unloadedPlugins)
          for error in Self.pluginEnvironment.errors {
            log.error("Error occured when loading plugin '\(error.bundle)': \(error.underlyingError)")
          }
        } catch {
          Self.modalError("Error occurred during plugin loading, no plugins will be available: \(error)")
        }
        
        // Download vanilla assets if they haven't already been downloaded
        if !StorageManager.default.directoryExists(at: StorageManager.default.vanillaAssetsDirectory) {
          updateLoadingState(step: .downloadAssets)
          try ResourcePack.downloadVanillaAssets(forVersion: Constants.versionString, to: StorageManager.default.vanillaAssetsDirectory) { progress, message in
            updateLoadingState(step: .downloadAssets, message: message, taskProgress: progress)
          }
        }
        
        // Load registries
        updateLoadingState(step: .loadRegistries)
        try RegistryStore.populateShared(StorageManager.default.registryDirectory) { progress, message in
          updateLoadingState(step: .loadRegistries, message: message, taskProgress: progress)
        }
        
        // Load resource pack and cache it if necessary
        updateLoadingState(step: .loadResourcePacks)
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
        
        updateLoadingState(step: .finish)
        
        // Get user to login if they haven't already
        if ConfigManager.default.config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }
        
        // Finish loading
        let elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - start) * 1000
        log.info(String(format: "Done (%.2fms)", elapsedMilliseconds))
        
        Self.loadingState.update(to: .done(LoadedResources(resourcePack: resourcePack)))
      } catch {
        Self.loadingState.update(to: .error("Failed to load: \(error)"))
      }
    }
  }

  static func handleCommandLineArguments() {
    let arguments = CommandLineArguments.parseOrExit()

    if let pluginsDirectory = arguments.pluginsDirectory {
      StorageManager.default.pluginsDirectory = pluginsDirectory
    }

    setLogLevel(arguments.logLevel)
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
          if case .none = Self.modalState.current, case .done = Self.loadingState.current {
            switch Self.appState.current {
              case .serverList, .editServerList, .accounts, .login, .directConnect:
                Self.appState.update(to: .settings(nil))
              case .playServer, .settings, .fatalError:
                break
            }
          }
        }
        .keyboardShortcut(KeyboardShortcut(KeyEquivalent(","), modifiers: [.command]))
      })
      CommandGroup(after: .windowSize, addition: {
        Button("Toggle Full Screen") {
          NSApp?.windows.first?.toggleFullScreen(nil)
        }
        .keyboardShortcut(KeyboardShortcut(KeyEquivalent("f"), modifiers: [.control, .command]))
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
