import SwiftUI
import DeltaCore

/// Gets the currently selected account, or redirects the user to settings to select an
/// account.
struct WithSelectedAccount<Content: View>: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var modal: Modal
  @EnvironmentObject var managedConfig: ManagedConfig

  var content: (Account) -> Content

  init(@ViewBuilder content: @escaping (Account) -> Content) {
    self.content = content
  }

  var body: some View {
    if let account = managedConfig.config.selectedAccount {
      content(account)
    } else {
      Text("Loading account...")
        .onAppear {
          modal.error("You must select an account.") {
            // TODO: Have an inline account selector instead of redirecting to settings.
            appState.update(to: .settings(.accounts))
          }
        }
    }
  }
}
