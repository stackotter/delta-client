import SwiftUI
import DeltaCore

enum SettingsState: CaseIterable {
  case video
  case controls
  case accounts
  case update
  case plugins
  case troubleshooting
}

struct SettingsView: View {
  var isInGame: Bool
  var client: Client?
  var done: () -> Void
  
  @State private var currentPage: SettingsState?
  
  init(
    isInGame: Bool,
    client: Client?,
    landingPage: SettingsState? = nil,
    onDone done: @escaping () -> Void
  ) {
    self.isInGame = isInGame
    self.client = client
    self.done = done
    self._currentPage = State(initialValue: landingPage ?? SettingsState.allCases[0])
  }
  
  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          "Video",
          destination: VideoSettingsView(client: client).padding(),
          tag: SettingsState.video,
          selection: $currentPage)
        NavigationLink(
          "Controls",
          destination: ControlsSettingsView().padding(),
          tag: SettingsState.controls,
          selection: $currentPage)
        
        if !isInGame {
          NavigationLink(
            "Accounts",
            destination: AccountSettingsView().padding(),
            tag: SettingsState.accounts,
            selection: $currentPage)
          NavigationLink(
            "Update",
            destination: UpdateView().padding(),
            tag: SettingsState.update,
            selection: $currentPage)
          NavigationLink(
            "Plugins",
            destination: PluginSettingsView().padding(),
            tag: SettingsState.plugins,
            selection: $currentPage)
          NavigationLink(
            "Troubleshooting",
            destination: TroubleshootingView().padding(),
            tag: SettingsState.troubleshooting,
            selection: $currentPage)
        }
        
        Button("Done", action: {
          withAnimation(nil) { done() }
        })
          .buttonStyle(BorderlessButtonStyle())
          .padding(.top, 8)
          .keyboardShortcut(.escape, modifiers: [])
      }
      .listStyle(SidebarListStyle())
    }
    .navigationTitle("Settings")
  }
}
