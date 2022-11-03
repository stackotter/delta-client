import Foundation

public class Pinger: ObservableObject {
  @Published public var response: Result<StatusResponse, PingError>?

  public var connection: ServerConnection?
  public let descriptor: ServerDescriptor

  public var shouldPing = false
  public var isConnecting = false

  private let queue: DispatchQueue

  // MARK: Init

  public init(_ descriptor: ServerDescriptor) {
    self.descriptor = descriptor
    queue = DispatchQueue(label: "dev.stackotter.delta-client.pinger-\(descriptor.name)")
    connect()
  }

  // MARK: Interface

  private func handleNetworkEvent(_ event: Event) {
    switch event {
      case let event as ConnectionFailedEvent:
        ThreadUtil.runInMain {
          response = Result.failure(PingError.connectionFailed(event.networkError))
        }
      default:
        break
    }
  }

  public func ping() throws {
    if let connection = connection {
      ThreadUtil.runInMain {
        response = nil
      }
      try connection.ping()
      shouldPing = false
    } else if !isConnecting {
      shouldPing = true
      connect()
    } else {
      shouldPing = true
    }
  }

  private func connect() {
    isConnecting = true
    // DNS resolution sometimes takes a while so we do that in parallel
    queue.async {
      do {
        let connection = try ServerConnection(descriptor: self.descriptor)
        connection.setPacketHandler(self.handlePacket)
        connection.eventBus.registerHandler(self.handleNetworkEvent)
        self.connection = connection
        self.isConnecting = false
        if self.shouldPing {
          try? self.ping()
        }
      } catch {
        log.trace("Failed to create server connection")
        ThreadUtil.runInMain {
          self.response = Result.failure(.connectionFailed(error))
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
