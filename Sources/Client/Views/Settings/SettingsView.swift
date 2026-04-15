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
  var done: () -> Void

  @State private var currentPage: SettingsState?

  init(
    isInGame: Bool,
    landingPage: SettingsState? = nil,
    onDone done: @escaping () -> Void
  ) {
    self.isInGame = isInGame
    self.done = done

    #if os(iOS) || os(tvOS)
      // On iOS, the navigation isn't a split view, so we should show the settings page selection
      // view first instead of auto-selecting the first page.
      self._currentPage = State(initialValue: landingPage)
    #else
      self._currentPage = State(initialValue: landingPage ?? SettingsState.allCases[0])
    #endif
  }

  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          "Video",
          destination: VideoSettingsView().padding(),
          tag: SettingsState.video,
          selection: $currentPage
        )

        #if !os(tvOS)
        NavigationLink(
          "Controls",
          destination: ControlsSettingsView().padding(),
          tag: SettingsState.controls,
          selection: $currentPage
        )
        #endif

        if !isInGame {
          NavigationLink(
            "Accounts",
            destination: AccountSettingsView().padding(),
            tag: SettingsState.accounts,
            selection: $currentPage
          )

          #if os(macOS)
          NavigationLink(
            "Update",
            destination: UpdateView().padding(),
            tag: SettingsState.update,
            selection: $currentPage
          )
          NavigationLink(
            "Plugins",
            destination: PluginSettingsView().padding(),
            tag: SettingsState.plugins,
            selection: $currentPage
          )
          #endif

          NavigationLink(
            "Troubleshooting",
            destination: TroubleshootingView().padding(),
            tag: SettingsState.troubleshooting,
            selection: $currentPage
          )
        }

        Button("Done", action: {
          withAnimation(nil) {
            done()
          }
        })
          #if !os(tvOS)
          .buttonStyle(BorderlessButtonStyle())
          .keyboardShortcut(.escape, modifiers: [])
          #endif
      }
      #if !os(tvOS)
      .listStyle(SidebarListStyle())
      #endif
    }
    .navigationTitle("Settings")
  }
}
