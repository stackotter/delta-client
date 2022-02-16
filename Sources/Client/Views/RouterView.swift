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
            case let .loadingWithMessage(message, progress):
              ProgressLoadingView(progress: progress, message: message)
            case let .error(message):
              TroubleshootingView(fatalErrorMessage: message)
            case let .done(loadedResources):
              mainView(loadedResources)
          }
        case .warning(let message):
          WarningView(message: message)
        case .error(let message, let safeState):
          ErrorView(message: message, safeState: safeState)
      }
    }.onChange(of: appState.current) { newValue in
      // Update Discord rich presence based on the current app state
      switch newValue {
        case .serverList:
          DiscordManager.shared.updateRichPresence(to: .menu)
        case .playServer(let descriptor):
          DiscordManager.shared.updateRichPresence(to: .game(server: descriptor.name))
        default:
          break
      }
    }
  }
  
  func mainView(_ loadedResources: LoadedResources) -> some View {
    VStack {
      switch appState.current {
        case .serverList:
          ServerListView()
        case .editServerList:
          EditServerListView()
        case .login:
          AccountLoginView(completion: { account in
            ConfigManager.default.addAccount(account, shouldSelect: true)
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
            GameView(
              serverDescriptor: descriptor,
              resourcePack: loadedResources.resourcePack,
              inputCaptureEnabled: inputCaptureEnabled,
              delegateSetter: setDelegate)
          }
        case .fatalError(let message):
          FatalErrorView(message: message)
        case .settings(let landingPage):
          SettingsView(isInGame: false, client: nil, landingPage: landingPage, onDone: {
            appState.pop()
          })
      }
    }
  }
}
