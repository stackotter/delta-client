import SwiftUI
import DeltaCore

enum ServerJoinState {
  case connecting
  case loggingIn
  case downloadingChunks(received: Int, total: Int)
  case joined

  var message: String {
    switch self {
      case .connecting:
        return "Establishing connection..."
      case .loggingIn:
        return "Logging in..."
      case .downloadingChunks:
        return "Downloading terrain..."
      case .joined:
        return "Joined successfully"
    }
  }
}

enum ServerJoinError: LocalizedError {
  case failedToRefreshAccount
  case failedToSendJoinServerRequest

  var errorDescription: String? {
    switch self {
      case .failedToRefreshAccount:
        return "Failed to refresh account."
      case .failedToSendJoinServerRequest:
        return "Failed to send join server request."
    }
  }
}

struct JoinServerAndThen<Content: View>: View {
  @EnvironmentObject var resourcePack: Box<ResourcePack>
  @EnvironmentObject var pluginEnvironment: PluginEnvironment
  @EnvironmentObject var managedConfig: ManagedConfig
  @EnvironmentObject var modal: Modal

  @State var state: ServerJoinState = .connecting
  @State var client: Client?

  /// Both `timeReceived` and `terrainDownloaded` must be true for us
  /// to be considered joined. This prevents annoying visual flashes caused
  /// by the time changing shortly after rendering begins.
  @State var timeReceived = false
  @State var terrainDownloaded = false

  var serverDescriptor: ServerDescriptor
  /// Beware that this account may be outdated once the server has been
  /// joined, as the account may have been refreshed. It should only be
  /// used to join once (or only for its id and username).
  var account: Account
  var content: (Client) -> Content
  var cancel: () -> Void

  init(
    _ serverDescriptor: ServerDescriptor,
    with account: Account,
    @ViewBuilder content: @escaping (Client) -> Content,
    cancellationHandler cancel: @escaping () -> Void
  ) {
    self.serverDescriptor = serverDescriptor
    self.account = account
    self.content = content
    self.cancel = cancel
  }

  var body: some View {
    VStack {
      switch state {
        case .connecting, .loggingIn, .downloadingChunks:
          Text(state.message)

          if case let .downloadingChunks(received, total) = state {
            HStack {
              ProgressView(value: Double(received) / Double(total))
              Text("\(received) of \(total)")
            }
            #if !os(tvOS)
            .frame(maxWidth: 200)
            #endif
          }

          Button("Cancel", action: cancel)
            .buttonStyle(SecondaryButtonStyle())
            #if !os(tvOS)
            .frame(width: 150)
            #endif
        case .joined:
          if let client = client {
            content(client)
          } else {
            Text("Loading...").onAppear {
              modal.error(RichError("UI entered invalid state while joining server.")) {
                cancel()
              }
            }
          }
      }
    }
    .onAppear {
      let client = Client(
        resourcePack: resourcePack.value,
        configuration: managedConfig
      )

      pluginEnvironment.addEventBus(client.eventBus)
      pluginEnvironment.handleWillJoinServer(server: serverDescriptor, client: client)

      Task {
        do {
          try await joinServer(serverDescriptor, with: account, client: client)
        } catch {
          modal.error(error)
          cancel()
        }
      }

      // An internal state variable used to reduce the number of state updates performed
      // when downloading chunks (otherwise it lags SwiftUI).
      var received = 0
      client.eventBus.registerHandler { [weak client] event in
        guard let client = client else {
          return
        }

        handleEvent(&received, client, event)
      }

      self.client = client
    }
    .onDisappear {
      client?.disconnect()
    }
  }

  func handleEvent(_ received: inout Int, _ client: Client, _ event: Event) {
    // TODO: Clean up Events API (there should probably just be one error event, see what the Discord
    //   server reckons)
    switch event {
      case _ as LoginStartEvent:
        ThreadUtil.runInMain {
          state = .loggingIn
        }
      case let connectionFailedEvent as ConnectionFailedEvent:
        modal.error(
          RichError("Connection to \(serverDescriptor) failed.")
            .becauseOf(connectionFailedEvent.networkError)
        ) {
          cancel()
        }
      case _ as JoinWorldEvent:
        // Approximation of the number of chunks the server will send (used in progress indicator)
        let totalChunksToReceieve = Int(Foundation.pow(Double(client.game.maxViewDistance * 2 + 3), 2))
        state = .downloadingChunks(received: 0, total: totalChunksToReceieve)
      case _ as World.Event.AddChunk:
        ThreadUtil.runInMain {
          if case let .downloadingChunks(_, total) = state {
            // An intermediate variable is used to reduce the number of SwiftUI updates generated by downloading chunks
            received += 1
            if received % 50 == 0 {
              state = .downloadingChunks(received: received, total: total)
            }
          }
        }
      case _ as TerrainDownloadCompletionEvent:
        terrainDownloaded = true
        if timeReceived {
          state = .joined
        }
      case _ as World.Event.TimeUpdate:
        timeReceived = true
        if terrainDownloaded {
          state = .joined
        }
      case let disconnectEvent as LoginDisconnectEvent:
        modal.error(
          RichError("Disconnected from server during login.").with("Reason", disconnectEvent.reason)
        ) {
          cancel()
        }
      case let packetError as PacketHandlingErrorEvent:
        modal.error(
          RichError("Failed to handle packet with id \(packetError.packetId.hexWithPrefix).")
            .with("Reason", packetError.error)
        ) {
          cancel()
        }
      case let packetError as PacketDecodingErrorEvent:
        modal.error(
          RichError("Failed to decode packet with id \(packetError.packetId.hexWithPrefix).")
            .with("Reason", packetError.error)
        ) {
          cancel()
        }
      case let generalError as ErrorEvent:
        modal.error(RichError(generalError.message ?? "Client error.").becauseOf(generalError.error)) {
          cancel()
        }
      default:
        break
    }
  }

  func joinServer(
    _ descriptor: ServerDescriptor,
    with account: Account,
    client: Client
  ) async throws {
    // Refresh the account (if it's an online account) and then join the server
    let refreshedAccount: Account
    do {
      refreshedAccount = try await managedConfig.refreshAccount(withId: account.id)
    } catch {
      throw ServerJoinError.failedToRefreshAccount
        .with("Username", account.username)
        .becauseOf(error)
    }

    do {
      try client.joinServer(
        describedBy: descriptor,
        with: refreshedAccount
      )
    } catch {
      throw ServerJoinError.failedToSendJoinServerRequest.becauseOf(error)
    }
  }
}
