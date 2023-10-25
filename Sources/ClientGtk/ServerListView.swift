import SwiftCrossUI
import DeltaCore

enum DetailState {
  case addition
  case server(ServerDescriptor)
  case error(String)
}

class ServerListViewState: Observable {
  @Observed var servers: [ServerDescriptor] = []
  @Observed var detailState = DetailState.addition

  @Observed var name = ""
  @Observed var address = ""
}

struct ServerListView: View {
  var completionHandler: (ServerDescriptor) -> Void

  var state = ServerListViewState()

  var body: some ViewContent {
    NavigationSplitView {
      VStack {
        Button("Add server") {
          state.detailState = .addition
        }

        ScrollView {
          ForEach(state.servers) { server in
            Button(server.name) {
              state.detailState = .server(server)
            }
            .padding(.bottom, 5)
          }
        }
      }
      .frame(minWidth: 100)
      .padding(.trailing, 10)
    } detail: {
      VStack {
        switch state.detailState {
          case .addition:
            additionView
          case .server(let server):
            Text(server.name)
            if let port = server.port {
              Text("\(server.host):\(port)")
            } else {
              Text(server.host)
            }

            Button("Connect") {
              completionHandler(server)
            }
          case .error(let message):
            Text("Error: \(message)")
            Button ("Back") {
              state.detailState = .addition
            }
        }
      }
      .padding(.leading, 10)
    }
  }

  var additionView: some View {
    VStack {
      Text("Add server")
      TextField("Name", state.$name)
      TextField("Address", state.$address)
      
      Button("Add") {
        let parts = state.address.split(separator: ":")
        guard parts.count > 0, parts.count <= 2 else {
          state.detailState = .error("Invalid address")
          return
        }

        let host = String(parts[0])

        var port: UInt16?
        if parts.count == 2 {
          guard let parsed = UInt16(parts[1]) else {
            state.detailState = .error("Invalid port")
            return
          }
          port = parsed
        }

        let descriptor = ServerDescriptor(name: state.name, host: host, port: port)
        state.servers.append(descriptor)
        state.detailState = .server(descriptor)
        
        state.name = ""
        state.address = ""
      }
    }
  }
}
