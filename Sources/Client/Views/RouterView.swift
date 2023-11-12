import SwiftUI
import DeltaCore

struct RouterView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var managedConfig: ManagedConfig
  @EnvironmentObject var resourcePack: Box<ResourcePack>
  @EnvironmentObject var controllerHub: ControllerHub

  var body: some View {
    VStack {
      switch appState.current {
        case .serverList:
          ServerListView()
        case .editServerList:
          EditServerListView()
        case .login:
          AccountLoginView(completion: { account in
            managedConfig.config.addAccount(account)
            appState.update(to: .serverList)
          }, cancelation: nil)
        case .accounts:
          AccountSettingsView(saveAction: {
            appState.update(to: .serverList)
          }).padding()
        case .directConnect:
          DirectConnectView()
        case .playServer(let server):
          WithSelectedAccount { account in
            GameView(
              connectingTo: server,
              with: account,
              controller: controllerHub.currentController
            )
          }
        case .settings(let landingPage):
          SettingsView(isInGame: false, landingPage: landingPage, onDone: {
            appState.pop()
          })
      }
    }
    .onChange(of: appState.current) { newValue in
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
}
