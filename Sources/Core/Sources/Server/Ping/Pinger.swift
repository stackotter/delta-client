import Foundation

#if !canImport(Combine)
import OpenCombine
#endif

public class Pinger: ObservableObject {
  @Published public var response: Result<StatusResponse, PingError>?

  public var connection: ServerConnection?
  public let descriptor: ServerDescriptor

  public var shouldPing = false
  public var isConnecting = false

  // MARK: Init

  public init(_ descriptor: ServerDescriptor) {
    self.descriptor = descriptor
    Task {
      await connect()
    }
  }

  // MARK: Interface

  private func handleNetworkEvent(_ event: Event) {
    switch event {
      case let event as ConnectionFailedEvent:
        ThreadUtil.runInMain {
          self.response = .failure(PingError.connectionFailed(event.networkError))
        }
      default:
        break
    }
  }

  public func ping() async throws {
    if let connection = connection {
      ThreadUtil.runInMain {
        self.response = nil
      }
      try connection.ping()
      shouldPing = false
    } else if !isConnecting {
      shouldPing = true
      await connect()
    } else {
      shouldPing = true
    }
  }

  private func connect() async {
    isConnecting = true
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        do {
          let connection = try await ServerConnection(descriptor: self.descriptor)
          connection.setPacketHandler(self.handlePacket)
          connection.eventBus.registerHandler(self.handleNetworkEvent)
          self.connection = connection
          self.isConnecting = false
          if self.shouldPing {
            try? await self.ping()
          }
        } catch {
          self.isConnecting = false
          log.trace("Failed to create server connection")
          ThreadUtil.runInMain {
            self.response = .failure(.connectionFailed(error))
          }
        }
      }
    }
  }

  public func closeConnection() {
    connection?.close()
    connection = nil
  }

  // MARK: Networking

  private func handlePacket(_ packet: ClientboundPacket) {
    do {
      try packet.handle(for: self)
    } catch {
      closeConnection()
      log.error("Failed to handle packet: \(error)")
    }
  }
}

extension Pinger: Equatable {
  public static func == (lhs: Pinger, rhs: Pinger) -> Bool {
    return lhs.descriptor == rhs.descriptor
  }
}

extension Pinger: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(descriptor)
  }
}
