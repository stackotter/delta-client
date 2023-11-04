import SwiftUI
import DeltaCore

class Modal: ObservableObject {
  enum Content {
    case warning(String)
    case errorMessage(String)
    case error(Error)

    var message: String {
      switch self {
        case let .warning(message):
          return message
        case let .errorMessage(message):
          return message
        case let .error(error):
          if let richError = error as? RichError {
            return richError.richDescription
          } else {
            return error.localizedDescription
          }
      }
    }
  }

  var isPresented: Binding<Bool> {
    Binding {
      self.content != nil
    } set: { newValue in
      if !newValue {
        self.content = nil
        self.dismissHandler?()
      }
    }
  }

  @Published var content: Content?
  var dismissHandler: (() -> Void)?

  func warning(_ message: String, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.warning(message)
    ThreadUtil.runInMain {
      content = .warning(message)
      self.dismissHandler = dismissHandler
    }
  }

  func error(_ message: String, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.error(message)
    ThreadUtil.runInMain {
      content = .errorMessage(message)
      self.dismissHandler = dismissHandler
    }
  }

  func error(_ error: Error, onDismiss dismissHandler: (() -> Void)? = nil) {
    log.error(error.localizedDescription)
    ThreadUtil.runInMain {
      content = .error(error)
      self.dismissHandler = dismissHandler
    }
  }
}

/// The entry-point for Delta Client.
struct DeltaClientApp: App {
  @ObservedObject var appState = StateWrapper<AppState>(initial: .serverList)
  @ObservedObject var pluginEnvironment = PluginEnvironment()
  @ObservedObject var modal = Modal()

  @State var hasLoaded = false

  /// A Delta Client version.
  enum Version {
    /// A version such as `1.0.0`.
    case semantic(String)
    /// A nightly build's version (e.g. `ae348f8...`).
    case commit(String)
  }

  /// Gets the current client's version.
  static var version: Version {
    guard let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
      fatalError("Info.plist is missing a version string")
    }

    if versionString.hasPrefix("commit: ") {
      return .commit(String(versionString.dropFirst("commit: ".count)))
    } else {
      return .semantic(versionString)
    }
  }

  init() {
    do {
      try enableFileLogger(loggingTo: StorageManager.default.currentLogFile)
    } catch {
      modal.warning("File logging disabled: failed to setup log file")
    }

    Self.handleCommandLineArguments()

    DiscordManager.shared.updateRichPresence(to: .menu)
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
      LoadAndThen($hasLoaded) { storageDirectory, resourcePack, pluginEnvironment in
        RouterView(resourcePack: resourcePack)
          .environmentObject(resourcePack)
          .environmentObject(pluginEnvironment)
          .environment(\.storage, storageDirectory)
          .onAppear {
            // TODO: Make a nice clean onboarding experience
            if ConfigManager.default.config.selectedAccount == nil {
              appState.update(to: .accounts)
            }
          }
      }
        .environmentObject(modal)
        .environmentObject(appState)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Delta Client")
        .alert(isPresented: modal.isPresented) {
          Alert(title: Text("Error"), message: (modal.content?.message).map(Text.init), dismissButton: Alert.Button.default(Text("OK")))
        }
    }
    .commands {
      // Add preferences menu item and shortcut (cmd+,)
      CommandGroup(after: .appSettings, addition: {
        Button("Preferences") {
          guard hasLoaded, modal.content == nil else {
            return
          }

          switch appState.current {
            case .serverList, .editServerList, .accounts, .login, .directConnect:
              appState.update(to: .settings(nil))
            case .playServer, .settings, .fatalError:
              break
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
}
