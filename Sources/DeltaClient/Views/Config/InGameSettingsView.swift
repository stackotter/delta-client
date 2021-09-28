import SwiftUI
import DeltaCore

struct InGameSettingsView: View {
  /// Settings views use the event bus to update rendering in real time.
  var eventBus: EventBus
  
  var done: () -> Void
  
  init(eventBus: EventBus, onDone done: @escaping () -> Void) {
    self.eventBus = eventBus
    self.done = done
  }
  
  var body: some View {
    NavigationView {
      List {
        NavigationLink("Video", destination: VideoSettingsView(eventBus: eventBus).padding())
        Button("Done", action: done)
          .buttonStyle(BorderlessButtonStyle())
          .padding(.top, 8)
          .keyboardShortcut(.escape, modifiers: [])
      }
      .listStyle(SidebarListStyle())
    }
    .navigationTitle("In Game Settings")
    .presentedWindowToolbarStyle(UnifiedWindowToolbarStyle())
  }
}
