import Foundation

public class Pinger: ObservableObject {
  @Published public var pingResult: Result<PingInfo, PingError>?
  
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
          pingResult = Result.failure(PingError.connectionFailed(event.networkError))
        }
      default:
        break
    }
  }
  
  public func ping() {
    if let connection = connection {
      ThreadUtil.runInMain {
        pingResult = nil
      }
      connection.ping()
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
      // TODO: resolve dns stuff in server connection async cause it takes a while sometimes?
      let connection = ServerConnection(descriptor: self.descriptor)
      connection.setPacketHandler(self.handlePacket)
      connection.eventBus.registerHandler(self.handleNetworkEvent)
      self.connection = connection
      self.isConnecting = false
      if self.shouldPing {
        self.ping()
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
      log.error("Failed to handle packet: \(error.localizedDescription)")
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
