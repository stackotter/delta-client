import DeltaCore
import SwiftCrossUI

class ChatViewState: Observable {
  @Observed var error: String?
  @Observed var messages: [String] = []
  @Observed var message = ""
}

struct ChatView: View {
  var client: Client

  var state = ChatViewState()

  init(_ client: Client) {
    self.client = client
    client.eventBus.registerHandler(handleEvent)
  }

  func handleEvent(_ event: Event) {
    switch event {
      case let event as ChatMessageReceivedEvent:
        state.messages.append(
          event.message.content.toText(with: client.resourcePack.getDefaultLocale())
        )
      default:
        break
    }
  }

  var body: some View {
    if let error = state.error {
      Text(error)
    }

    TextField("Message", state.$message)
    Button("Send") {
      guard !state.message.isEmpty else {
        return
      }

      // TODO: Create api for sending chat messages
      do {
        try client.sendPacket(ChatMessageServerboundPacket(state.message))
      } catch {
        state.error = "Failed to send message: \(error)"
      }
      state.message = ""
    }

    ForEach(state.messages.reversed()) { message in
      Text(message)
    }
    .frame(minHeight: 200)
    .padding(.top, 10)
  }
}
