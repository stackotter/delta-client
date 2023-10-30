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
    do {
      try enableFileLogger(loggingTo: StorageManager.default.currentLogFile)
    } catch {
      Self.modalWarning("File logging disabled: failed to setup log file")
    }

    Self.handleCommandLineArguments()

    DiscordManager.shared.updateRichPresence(to: .menu)

    // Load plugins, registries and resources
    DispatchQueue(label: "test").async {
      var previousStep: StartupStep?
      let startup = TaskProgress<StartupStep>().onChange { progress in
        if progress.currentStep != previousStep {
          let percentage = String(format: "%.01f", progress.progress * 100)
          log.info("\(progress.message) (\(percentage)%)")
        }

        previousStep = progress.currentStep

        Self.loadingState.update(to: .loadingWithMessage(
          progress.message,
          progress: progress.progress
        ))
      }

      do {
        let stopwatch = Stopwatch()

        let config = ConfigManager.default.config

        guard let storage = StorageDirectory.platformDefault else {
          throw RichError("Failed to get storage directory")
        }
        try storage.ensureCreated()

        Task {
          await ConfigManager.default.refreshAccounts()
        }

        startup.perform(.loadPlugins) {
          try Self.pluginEnvironment.loadPlugins(
            from: storage.pluginDirectory,
            excluding: config.unloadedPlugins
          )
        } handleError: { error in
          Self.modalError("Error occurred during plugin loading, no plugins will be available: \(error)")
        }

        try startup.perform(.downloadAssets, if: !FileSystem.directoryExists(storage.assetDirectory)) { progressHandler in
          try ResourcePack.downloadVanillaAssets(
            forVersion: Constants.versionString,
            to: storage.assetDirectory,
            progressHandler: progressHandler
          )
        }

        try startup.perform(.loadRegistries) { progressHandler in
          try RegistryStore.populateShared(storage.registryDirectory, progressHandler: progressHandler)
        }

        // Load resource pack and cache it if necessary
        let resourcePack = try startup.perform(.loadResourcePacks) {
          let packCache = storage.cache(forResourcePackNamed: "vanilla")
          let resourcePack = try ResourcePack.load(from: storage.assetDirectory, cacheDirectory: packCache)
          if !FileSystem.directoryExists(packCache) {
            do {
              try resourcePack.cache(to: packCache)
            } catch {
              Self.modalWarning("Failed to cache vanilla resource pack")
            }
          }
          return resourcePack
        }

        // Get user to login if they haven't already
        if config.accounts.isEmpty {
          Self.appState.update(to: .login)
        }

        log.info("Finished loading (\(stopwatch.elapsed))")

        Self.loadingState.update(to: .done(LoadedResources(resourcePack: resourcePack)))
      } catch {
        Self.loadingState.update(to: .error(error))
      }
    }
  }

  static func handleCommandLineArguments() {
    let arguments = CommandLineArguments.parseOrExit()

    if let pluginsDirectory = arguments.pluginsDirectory {
      StorageManager.default.pluginsDirectory = pluginsDirectory
    }

    setConsoleLogLevel(arguments.logLevel)
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
      CommandGroup(after: .toolbar, addition: {
        Button("Logs") {
          NSWorkspace.shared.open(StorageManager.default.currentLogFile)
        }
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
    log.warning(message)
    Self.modalState.update(to: .warning(message))
  }

  /// Display a dismissible error and then transition to `safeState` if supplied.
  static func modalError(_ message: String, safeState: AppState? = nil) {
    log.error(message)
    Self.modalState.update(to: .error(message, safeState: safeState))
  }

  /// Logs a fatal error and then fatal errors.
  static func fatal(_ message: String) -> Never {
    log.critical(message)
    fatalError(message)
  }
}
