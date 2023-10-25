import SwiftCrossUI
import DeltaCore

indirect enum DetailState {
  case server(_ index: Int)
  case adding
  case editing(_ index: Int)

  case error(_ message: String, returnState: DetailState?)
  static func error(_ message: String) -> DetailState {
    return .error(message, returnState: nil)
  }
}

class ServerListViewState: Observable {
  @Observed var servers: [ServerDescriptor] = []
  @Observed var detailState = DetailState.adding

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
          state.detailState = .adding
        }

        ScrollView {
          ForEach(state.servers.indices) { index in
            Button(state.servers[index].name) {
              state.detailState = .server(index)
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
          case .server(let index):
            serverView(index)
          case .adding:
            addingView()
          case .editing(let index):
            editingView(index)
          case .error(let message, let returnState):
            Text("Error: \(message)")
            if let returnState {
              Button ("Back") {
                state.detailState = returnState
              }
            }
        }
      }
      .padding(.leading, 10)
    }
  }

  func serverView(_ index: Int) -> some View {
    let server = state.servers[index]

    return VStack {
      Text(server.name)
      if let port = server.port {
        Text("\(server.host):\(port)")
      } else {
        Text(server.host)
      }

      Button("Connect") {
        completionHandler(server)
      }

      Button("Edit") {
        state.name = server.name
        if let port = server.port {
          state.address = "\(server.host):\(port)"
        } else {
          state.address = "\(server.host)"
        }
        state.detailState = .editing(index)
      }
    }
  }

  func addingView() -> some View {
    return VStack {
      Text("Add server")
      TextField("Name", state.$name)
      TextField("Address", state.$address)
      
      Button("Add") {
        do {
          let (host, port) = try ServerListView.parseAddress(state.address)

          let descriptor = ServerDescriptor(name: state.name, host: host, port: port)
          state.servers.append(descriptor)
          state.detailState = .server(state.servers.count - 1)
          
          state.name = ""
          state.address = ""
        } catch AddressParsingError.invalidPort {
          state.detailState = .error("Invalid port", returnState: .adding)
        } catch {
          state.detailState = .error("Invalid address", returnState: .adding)
        }
      }
    }
  }

  func editingView(_ index: Int) -> some View {
    return VStack {
      Text("Edit server")
      TextField("Name", state.$name)
      TextField("Address", state.$address)

      Button("Apply") {
        do {
          let (host, port) = try ServerListView.parseAddress(state.address)

          state.servers[index].name = state.name
          state.servers[index].host = host
          state.servers[index].port = port
          state.detailState = .server(index)

          state.name = ""
          state.address = ""
        } catch AddressParsingError.invalidPort {
          state.detailState = .error("Invalid port", returnState: .editing(index))
        } catch {
          state.detailState = .error("Invalid address", returnState: .editing(index))
        }
      }

      Button("Remove") {
        state.servers.remove(at: index)
        state.name = ""
        state.address = ""
        if (state.servers.count > 0) {
          state.detailState = .server(0)
        } else {
          state.detailState = .adding
        }
      }
    }
  }

  private enum AddressParsingError: Error {
    case invalidColonAmount
    case invalidPort
  }

  private static func parseAddress(_ address: String) throws -> (host: String, port: UInt16?) {
    let parts = address.split(separator: ":")
    guard parts.count > 0, parts.count <= 2 else {
      throw AddressParsingError.invalidColonAmount
    }

    let host = String(parts[0])

    var port: UInt16?
    if parts.count == 2 {
      guard let parsed = UInt16(parts[1]) else {
        throw AddressParsingError.invalidPort
      }
      port = parsed
    }

    return (host, port)
  }
}
