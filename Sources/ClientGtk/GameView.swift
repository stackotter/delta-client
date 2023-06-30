import Dispatch
import SwiftCrossUI
import DeltaCore

class GameViewState: Observable {
  enum State {
    case error(String)
    case connecting
    case connected
  }

  var server: ServerDescriptor
  var client: Client

  @Observed var state = State.connecting

  init(_ server: ServerDescriptor, _ resourcePack: ResourcePack) {
    self.server = server
    client = Client(resourcePack: resourcePack)
    client.eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handleClientEvent(event)
    }

    do {
      // TODO: Use structured concurrency to get join server to wait until login is finished so that
      // errors can be handled inline
      try client.joinServer(describedBy: server, with: Account.offline(OfflineAccount(username: "epicgtk69")))
    } catch {
      state = .error("Failed to join server: \(error.localizedDescription)")
    }
  }

  func handleClientEvent(_ event: Event) {
    switch event {
      // TODO: This is absolutely ridiculous just for error handling. Unify all errors into a single
      // error event
      case let event as ConnectionFailedEvent:
        state = .error("Connection failed: \(event.networkError)")
      case is JoinWorldEvent:
        state = .connected
      case let event as LoginDisconnectEvent:
        state = .error("Disconnected from server during login:\n\n\(event.reason)")
      case let event as PlayDisconnectEvent:
        state = .error("Disconnected from server during play:\n\n\(event.reason)")
      case let packetError as PacketHandlingErrorEvent:
        let id = String(packetError.packetId, radix: 16)
        state = .error("Failed to handle packet with id 0x\(id):\n\n\(packetError.error)")
      case let packetError as PacketDecodingErrorEvent:
        let id = String(packetError.packetId, radix: 16)
        state = .error("Failed to decode packet with id 0x\(id):\n\n\(packetError.error)")
      case let event as ErrorEvent:
        if let message = event.message {
          state = .error("\(message): \(event.error)")
        } else {
          state = .error("\(event.error)")
        }
      default:
        break
    }
  }
}

struct GameView: View {
  var state: GameViewState

  init(_ server: ServerDescriptor, _ resourcePack: ResourcePack) {
    state = GameViewState(server, resourcePack)
  }

  var body: some ViewContent {
    switch state.state {
      case .error(let message):
        Text(message)
      case .connecting:
        Text("Connecting...")
      case .connected:
        ChatView(state.client)
    }
  }
}
