import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var loadingState: StateWrapper<LoadingState>
  
  var body: some View {
    Group {
      switch modalState.current {
        case .none:
          switch loadingState.current {
            case .loading:
              Text("Loading")
                .navigationTitle("Loading")
            case let .loadingWithMessage(message):
              Text(message)
                .navigationTitle("Loading")
            case let .error(message):
              FatalErrorView(message: message)
            case let .done(loadedResources):
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
                      log.error("Failed to select account")
                      appState.update(to: .fatalError("Failed to select account (something went very wrong)"))
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
                case .fatalError(let message):
                  FatalErrorView(message: message)
                case .settings:
                  SettingsView(isInGame: false, eventBus: nil, onDone: {
                    appState.pop()
                  })
              }
          }
        case .warning(let message):
          WarningView(message: message)
        case .error(let message, let safeState):
          ErrorView(message: message, safeState: safeState)
      }
    }.onChange(of: appState.current) { newValue in
      /// Updating discord rich presence based on current app state
      switch newValue {
        case .serverList: DiscordManager.shared.updateRichPresence(with: .menu)
        case .playServer(let descriptor): DiscordManager.shared.updateRichPresence(with: .game("Playing on \(descriptor.name)"))
        default: break
      }
    }
  }

}
