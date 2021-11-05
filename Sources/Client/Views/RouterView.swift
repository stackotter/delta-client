import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var startupState: StateWrapper<StartupState>
  @EnvironmentObject var loadingState: StateWrapper<LoadingState>
  
  var body: some View {
    Group {
      switch modalState.current {
        case .warning(let message):
          WarningView(message: message)
        case .error(let message, let safeState):
          ErrorView(message: message, safeState: safeState)
        case .none:
          switch startupState.current {
            case .loading:
              Text("Loading")
                .navigationTitle("Loading")
            case let .loadingWithMessage(message):
              generateLoadingView(with: message)
            case .fatalError:
              TroubleShootingView()
            case let .done(loadedResources):
              switch loadingState.current {
                case let .loadingWithMessage(message):
                  generateLoadingView(with: message)
                case .none, .done:
                  switch appState.current {
                    case .serverList:
                      ServerListView()
                    case .editServerList:
                      EditServerListView()
                    case .login:
                      AccountLoginView(completion: { account in
                        var config = ConfigManager.default.config
                        var accounts = config.accounts
                        accounts.append(account)
                        config.updateAccounts(accounts)
                        do {
                          try config.selectAccount(account)
                        } catch {
                          DeltaClientApp.fatal("Failed to select account (something went very wrong)")
                          return
                        }
                        ConfigManager.default.setConfig(to: config)
                        appState.update(to: .serverList)
                      }, cancelation: nil)
                    case .accounts:
                      AccountSettingsView(saveAction: {
                        appState.update(to: .serverList)
                      }).padding()
                    case .directConnect:
                      DirectConnectView()
                    case .playServer(let descriptor):
                      InputView { inputCaptureEnabled, setDelegate in
                        PlayServerView(
                          serverDescriptor: descriptor,
                          resourcePack: loadedResources.resourcePack,
                          inputCaptureEnabled: inputCaptureEnabled,
                          delegateSetter: setDelegate)
                      }
                    case .settings(let landingPage):
                      /** Simply calling getSettingsView once with the given landingPage doesn't cause States in `SettingsView`
                       to be properly initialised. A rather reduntant switch statement is needed.
                       */
                      switch landingPage {
                        case .accounts: getSettingsView(with: .accounts)
                        case .update: getSettingsView(with: .update)
                        case .troubleshooting: getSettingsView(with: .troubleshooting)
                        case .video: getSettingsView(with: .video)
                        case .plugins: getSettingsView(with: .plugins)
                        case .none: getSettingsView(with: .none)
                      }
                  }
              }
          }
      }
    }
  }
  
  /// Generates a pre-configured `SettingsView`
  ///
  /// - Parameter landingPage: the initial screen in `SettingsView` that should be selected
  /// - Returns: the configured `SettingsView`
  @ViewBuilder private func getSettingsView(with landingPage: SettingsState) -> some View {
    SettingsView(isInGame: false, eventBus: nil, landingPage: landingPage, onDone: {
      appState.pop()
    })
  }
  
  /// Generates a configured loading view
  ///
  /// - Parameter message: the loading message to be displayed on screen
  /// - Returns: the configured view
  @ViewBuilder private func generateLoadingView(with message: String) -> some View {
    Text(message)
      .navigationTitle("Loading")
  }
  
}
