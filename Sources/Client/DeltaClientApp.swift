import SwiftUI
import DeltaCore

/// The entry-point for Delta Client.
struct DeltaClientApp: App {
  @StateObject var appState = StateWrapper<AppState>(initial: .serverList)
  @StateObject var pluginEnvironment = PluginEnvironment()
  @StateObject var modal = Modal()
  @StateObject var controllerHub = ControllerHub()

  @State var storage: StorageDirectory?

  @State var hasLoaded = false

  let arguments: CommandLineArguments

  /// A Delta Client version.
  enum Version {
    /// A version such as `1.0.0`.
    case semantic(String)
    /// A nightly build's version (e.g. `ae348f8...`).
    case commit(String)
  }

  /// Gets the current client's version. `nil` if the app doesn't have an `Info.plist` or
  /// the `CFBundleShortVersionString` key is missing.
  static var version: Version? {
    guard let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
      return nil
    }

    if versionString.hasPrefix("commit: ") {
      return .commit(String(versionString.dropFirst("commit: ".count)))
    } else {
      return .semantic(versionString)
    }
  }

  init() {
    arguments = CommandLineArguments.parseOrExit()
    setConsoleLogLevel(arguments.logLevel)

    DiscordManager.shared.updateRichPresence(to: .menu)
  }

  var body: some Scene {
    WindowGroup {
      LoadAndThen(arguments, $hasLoaded, $storage) { managedConfig, resourcePack, pluginEnvironment in
        RouterView()
          .environmentObject(resourcePack)
          .environmentObject(pluginEnvironment)
          .environmentObject(managedConfig)
          .onAppear {
            // TODO: Make a nice clean onboarding experience
            if managedConfig.selectedAccountId == nil {
              appState.update(to: .login)
            }
          }
      }
        .environment(\.storage, storage ?? StorageDirectoryEnvironmentKey.defaultValue)
        .environmentObject(modal)
        .environmentObject(appState)
        .environmentObject(controllerHub)
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
            case .playServer, .settings:
              break
          }
        }
        .keyboardShortcut(KeyboardShortcut(KeyEquivalent(","), modifiers: [.command]))
      })
      CommandGroup(after: .toolbar, addition: {
        Button("Logs") {
          guard let file = storage?.currentLogFile else {
            modal.error("File logging not enabled yet")
            return
          }
          NSWorkspace.shared.open(file)
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
