import SwiftUI
import DeltaCore

struct SettingsView: View {
  var isInGame: Bool
  var eventBus: EventBus?
  var done: () -> Void
  
  init(isInGame: Bool, eventBus: EventBus?, onDone done: @escaping () -> Void) {
    self.isInGame = isInGame
    self.eventBus = eventBus
    self.done = done
  }
  
  var body: some View {
    NavigationView {
      List {
        if !isInGame {
          NavigationLink("Controls", destination: ControlsView().padding())
          NavigationLink("Accounts", destination: AccountSettingsView().padding())
          NavigationLink("Update", destination: UpdateView().padding())
          NavigationLink("Plugins", destination: PluginView().padding())
        }
        
        NavigationLink("Video", destination: VideoSettingsView(eventBus: eventBus).padding())
        
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
