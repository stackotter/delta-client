import SwiftUI
import DeltaCore
import Combine

struct EditServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var servers = ConfigManager.default.config.servers
  
  func save() {
    var config = ConfigManager.default.config
    config.servers = servers
    ConfigManager.default.setConfig(to: config)
    appState.pop()
  }
  
  var body: some View {
    VStack {
      EditableList(
        $servers,
        itemEditor: ServerEditorView.self,
        row: { item, selected, isFirst, isLast, handler in
          HStack {
            VStack {
              IconButton("chevron.up", isDisabled: isFirst) { handler(.moveUp) }
              IconButton("chevron.down", isDisabled: isLast) { handler(.moveDown) }
            }
            
            VStack(alignment: .leading) {
              Text(item.name)
                .font(.headline)
              Text(item.description)
                .font(.subheadline)
            }
            
            Spacer()
            
            HStack {
              IconButton("square.and.pencil") { handler(.edit) }
              IconButton("xmark") { handler(.delete) }
            }
          }
        },
        saveAction: save,
        cancelAction: appState.pop,
        emptyMessage: "No servers")
    }
    .padding()
    .navigationTitle("Edit Servers")
  }
}
