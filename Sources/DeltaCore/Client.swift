import Foundation

public enum ClientError: LocalizedError {
  /// Players must login before they can join a server.
  case loginRequired
}

/// A client creates and maintains a connection to a server while handling/storing all received data.
public class Client {
  /// The connection to the current server.
  public var connection: ServerConnection?
  /// The current server. Created once a `JoinGamePacket` is received.
  public var server: Server?
  /// The event bus for this client instance.
  public var eventBus = EventBus()
  /// The resource pack to use.
  public var resourcePack: ResourcePack
  /// The account this client uses to join servers.
  public var account: Account?
  /// The most recent time this client joined a server (specifically, when the join game packet was received). Used to calculate client tick.
  public var joinServerTime: CFAbsoluteTime?
  
  // TODO: ABOLISH world update batching, it's confusing and annoying
  /// Whether to batch world updates or not.
  private var _batchWorldUpdates = true
  public var batchWorldUpdates: Bool {
    get {
      _batchWorldUpdates
    }
    set(newValue) {
      if newValue != _batchWorldUpdates {
        if newValue {
          server?.world.enableBatching()
        } else {
          server?.world.disableBatching()
        }
        _batchWorldUpdates = newValue
      }
    }
  }
  
  public var renderDistance = 1
  
  // MARK: Init
  
  public init(resourcePack: ResourcePack) {
    self.resourcePack = resourcePack
    
    eventBus.registerHandler(handleEvent)
  }
  
  // MARK: Other
  
  /// Returns the current client tick (as opposed to the server tick).
  public func getClientTick() -> Int {
    if let start = joinServerTime {
      return Int(((CFAbsoluteTimeGetCurrent() - start) * 20.0).rounded(.down))
    } else {
      return 0
    }
  }
  
  // MARK: Connection lifecycle
  
  /// Join the specified server.
  public func joinServer(describedBy descriptor: ServerDescriptor, with account: Account, onFailure failure: @escaping (Error) -> Void) {
    self.account = account
    
    // Create a connection to the server
    let connection = ServerConnection(descriptor: descriptor, locale: resourcePack.getDefaultLocale())
    connection.setPacketHandler(handlePacket(_:))
    connection.login(username: account.username)
    self.connection = connection
  }
  
  /// Disconnect from the currently connected server if any.
  public func closeConnection() {
    connection?.close()
    connection = nil
    server = nil
  }
  
  // MARK: Networking
  
  /// Send a packet to the server currently connected to (if any).
  public func sendPacket(_ packet: ServerboundPacket) {
    connection?.sendPacket(packet)
  }
  
  /// The client's packet handler.
  public func handlePacket(_ packet: ClientboundPacket) {
    do {
      try packet.handle(for: self)
    } catch {
      closeConnection()
      log.error("Failed to handle packet: \(error)")
      eventBus.dispatch(PacketHandlingErrorEvent(packetId: type(of: packet).id, error: "\(error)"))
    }
  }
  
  // MARK: Event
  
  private func handleEvent(_ event: Event) {
    switch event {
      case let inputEvent as InputEvent:
        server?.player.updateInputs(with: inputEvent)
      case let mouseEvent as MouseMoveEvent:
        server?.player.updateLook(with: mouseEvent)
      case let changeRenderDistanceEvent as ChangeRenderDistanceEvent:
        renderDistance = changeRenderDistanceEvent.renderDistance
      default:
        break
    }
  }
}
