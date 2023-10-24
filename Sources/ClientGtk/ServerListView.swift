import SwiftCrossUI
import DeltaCore

enum DetailState {
  case addition, server(ServerDescriptor), error(String)
}

class ServerListViewState: Observable {
  @Observed var servers: [ServerDescriptor] = []
  @Observed var detailState = DetailState.addition
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
            .padding(Edge.Set.bottom, 5)
          }
        }
      }
      .frame(minWidth: 100)
      .padding(Edge.Set.trailing, 10)
    } detail: {
      VStack {
        switch state.detailState {
          case .addition:
            additionView
          case .server(let server):
            Text(server.name)
            if let port = server.port {
              Text(server.host + ":" + String(port))
            } else {
              Text(server.host)
            }

            Button("Connect") {
              completionHandler(server)
            }
          case .error(let message):
            Text(message)
        }
      }
      .padding(Edge.Set.leading, 10)
    }
  }

  var additionView: some View {
    VStack {
      @Observed var name = ""
      @Observed var address = ""

      Text("Add server")
      TextField("Name", $name)
      TextField("Address", $address)
      
      Button("Add") {
        let parts = address.split(separator: ":")
        guard parts.count <= 2 else {
          state.detailState = .error("Too many colons")
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

        let descriptor = ServerDescriptor(name: name, host: host, port: port)
        state.servers.append(descriptor)
        state.detailState = .server(descriptor)
      }
    }
  }
}
