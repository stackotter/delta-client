import SwiftUI
import DeltaCore

struct ServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var pingers: [Pinger]
  
  init() {
    let servers = ConfigManager.default.config.servers
    
    _pingers = State(initialValue: servers.map { server in
      Pinger(server)
    })
    
    refresh()
  }
  
  /// Ping all servers
  func refresh() {
    for pinger in pingers {
      pinger.ping()
    }
  }
  
  var body: some View {
    NavigationView {
      List {
        if !pingers.isEmpty {
          ForEach(pingers, id: \.self) { pinger in
            NavigationLink(destination: ServerDetail(pinger: pinger)) {
              ServerListItem(pinger: pinger)
            }
          }
        } else {
          Text("no servers").italic()
        }
        
        HStack {
          // Edit
          IconButton("square.and.pencil") {
            appState.update(to: .editServerList)
          }
          // Refresh servers
          IconButton("arrow.clockwise") {
            refresh()
          }
          // Direct connect
          IconButton("personalhotspot") {
            appState.update(to: .directConnect)
          }
          // Settings
          IconButton("gear") {
            appState.update(to: .settings(.none))
          }
        }
      }
    }
  }
}
