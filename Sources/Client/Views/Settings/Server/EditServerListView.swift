import SwiftUI
import DeltaCore
import Combine

struct EditServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var servers = ConfigManager.default.config.servers
  @State var isAddingServer = false
  
  func save() {
    var config = ConfigManager.default.config
    config.servers = servers
    ConfigManager.default.setConfig(to: config)
    appState.pop()
  }
  
  var body: some View {
    VStack(spacing: 50) {
      if isAddingServer {
        ServerEditorView(nil) { newItem in
          servers.append(newItem)
          save()
          isAddingServer = false
        } cancelation: {
          isAddingServer = false
        }
      } else {
        DirectConnectView()
          .frame(width: 400, alignment: .leading)
        
        EditableList(
          $servers,
          itemEditor: ServerEditorView.self,
          row: { item, selected, isFirst, isLast, handler in
            HStack {
              VStack(alignment: .leading, spacing: 3.5) {
                Text(item.name)
                  .font(Font.custom(.worksans, size: 15.5))
                  .foregroundColor(.white)
                Text(item.description)
                  .font(Font.custom(.worksans, size: 13))
                  .foregroundColor(.white)
              }
              
              Spacer()
              
              HStack(spacing: 12.5) {
                Button { handler(.delete) } label: {
                  Image(systemName: "trash")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                Button { appState.update(to: .playServer(item)) } label: {
                  Image(systemName: "play")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 7.5)
            .background(Color.lightGray)
            .cornerRadius(4)
            .padding(.bottom, 5)
          },
          saveAction: save,
          cancelAction: appState.pop,
          addAction: { isAddingServer.toggle() },
          emptyMessage: "No servers",
          title: "Server list")
          .background(Color.black)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.vertical, 50)
    .background(Color.black)
    .navigationTitle("Edit Servers")
  }
}
