import SwiftUI
import DeltaCore

struct SettingsView: View {
  var isInGame: Bool
  var client: Client?
  var done: () -> Void
  
  init(isInGame: Bool, client: Client?, onDone done: @escaping () -> Void) {
    self.isInGame = isInGame
    self.client = client
    self.done = done
  }
  
  var body: some View {
    NavigationView {
      List {
        NavigationLink("Video", destination: VideoSettingsView(client: client))
        NavigationLink("Controls", destination: ControlsSettingsView())
        
        if !isInGame {
          NavigationLink("Accounts", destination: AccountSettingsView().padding())
          NavigationLink("Update", destination: UpdateView().padding())
          NavigationLink("Plugins", destination: PluginSettingsView().padding())
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
