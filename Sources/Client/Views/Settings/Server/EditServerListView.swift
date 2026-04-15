import SwiftUI
import DeltaCore
import Combine

struct EditServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var managedConfig: ManagedConfig
  
  @State var servers: [ServerDescriptor] = []
  
  var body: some View {
    VStack {
      EditableList(
        $managedConfig.servers,
        itemEditor: ServerEditorView.self,
        row: { item, selected, isFirst, isLast, handler in
          HStack {
            #if !os(tvOS)
            VStack {
              IconButton("chevron.up", isDisabled: isFirst) { handler(.moveUp) }
              IconButton("chevron.down", isDisabled: isLast) { handler(.moveDown) }
            }
            #endif
            
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
                #if os(tvOS)
                .padding(.trailing, 20)
                #endif
            }
          }
        },
        saveAction: appState.pop,
        cancelAction: appState.pop, // TODO: There is no cancel anymore
        emptyMessage: "No servers")
    }
    .padding()
    .navigationTitle("Edit Servers")
  }
}
