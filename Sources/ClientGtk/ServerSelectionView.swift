import SwiftCrossUI
import DeltaCore

class ServerSelectionState: ViewState {
  @Observed var address = ""
  @Observed var error: String?
}

struct ServerSelectionView: View {
  var completionHandler: (ServerDescriptor) -> Void

  var state = ServerSelectionState()

  var body: some ViewContent {
    if let error = state.error {
      Text(error)
    }

    TextField("Address", state.$address)

    Button("Connect") {
      let parts = state.address.split(separator: ":")
      guard parts.count <= 2 else {
        state.error = "Too many colons"
        return
      }

      let host = String(parts[0])

      var port: UInt16?
      if parts.count == 2 {
        guard let parsed = UInt16(parts[1]) else {
          state.error = "Invalid port"
          return
        }
        port = parsed
      }

      completionHandler(ServerDescriptor(name: "direct", host: host, port: port))
    }
  }
}
