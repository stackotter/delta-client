import SwiftUI
import DeltaCore

enum SettingsState {
  case none, accounts, plugins, update, troubleshooting, video
}

struct SettingsView: View {
  var isInGame: Bool
  var eventBus: EventBus?
  var done: () -> Void
  
  /// The `NavigationLink` to be selected on initializaiton
  @State private var initialLandingPage: SettingsState? = nil
  
  init(
    isInGame: Bool,
    eventBus: EventBus?,
    landingPage: SettingsState? = nil,
    onDone done: @escaping () -> Void
  ) {
    self.isInGame = isInGame
    self.eventBus = eventBus
    self.done = done
    self._initialLandingPage = State(initialValue: landingPage)
  }
  
  var body: some View {
    NavigationView {
      List {
        if !isInGame {
          NavigationLink(
            "Accounts",
            destination: AccountSettingsView().padding(),
            tag: SettingsState.accounts,
            selection: $initialLandingPage)
          NavigationLink(
            "Update",
            destination: UpdateView().padding(),
            tag: SettingsState.update,
            selection: $initialLandingPage)
          NavigationLink(
            "Troubleshooting",
            destination: TroubleShootingView(),
            tag: SettingsState.troubleshooting,
            selection: $initialLandingPage)
          NavigationLink(
            "Plugins",
            destination: PluginView().padding(),
            tag: SettingsState.plugins,
            selection: $initialLandingPage)
        }
        
        NavigationLink("Video",
                       destination: VideoSettingsView(eventBus: eventBus).padding(),
                       tag: SettingsState.video,
                       selection: $initialLandingPage)
        
        Button("Done", action: done)
          .buttonStyle(BorderlessButtonStyle())
          .padding(.top, 8)
          .keyboardShortcut(.escape, modifiers: [])
      }
      .listStyle(SidebarListStyle())
    }
    .navigationTitle("Settings")
  }
}
