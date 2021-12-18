import Foundation

/// A client creates and maintains a connection to a server and handles the received packets.
public class Client {
  /// The resource pack to use.
  public var resourcePack: ResourcePack
  /// The account this client uses to join servers.
  public var account: Account?
  
  /// The game this client is playing in.
  public var game: Game
  /// The client's configuration
  public var configuration = ClientConfiguration()
  
  /// The connection to the current server.
  public var connection: ServerConnection?
  /// An event bus shared with ``game``.
  public var eventBus = EventBus()
  
  // MARK: Init
  
  public init(resourcePack: ResourcePack) {
    self.resourcePack = resourcePack
    game = Game(eventBus: eventBus)
    eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handleEvent(event)
    }
  }
  
  // MARK: Connection lifecycle
  
  /// Join the specified server.
  public func joinServer(describedBy descriptor: ServerDescriptor, with account: Account, onFailure failure: @escaping (Error) -> Void) {
    self.account = account
    
    // Create a connection to the server
    let connection = ServerConnection(descriptor: descriptor, locale: resourcePack.getDefaultLocale(), eventBus: eventBus)
    connection.setPacketHandler(handlePacket(_:))
    connection.login(username: account.username)
    self.connection = connection
  }
  
  /// Disconnect from the currently connected server if any.
  public func closeConnection() {
    connection?.close()
    connection = nil
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
        game.player.updateInputs(with: inputEvent)
      case let mouseEvent as MouseMoveEvent:
        game.player.updateLook(with: mouseEvent)
      default:
        break
    }
  }
}
