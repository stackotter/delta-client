import Foundation

// TODO: Make client actually Sendable

/// A client creates and maintains a connection to a server and handles the received packets.
public final class Client: @unchecked Sendable {
  // MARK: Public properties
  
  /// The resource pack to use.
  public let resourcePack: ResourcePack
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
  
  /// Creates a new client instance.
  /// - Parameter resourcePack: The resources to use.
  public init(resourcePack: ResourcePack) {
    self.resourcePack = resourcePack
    game = Game(eventBus: eventBus)
  }
  
  deinit {
    game.tickScheduler.cancel()
    connection?.close()
  }
  
  // MARK: Connection lifecycle
  
  /// Join the specified server. Throws if the packets fail to send.
  public func joinServer(describedBy descriptor: ServerDescriptor, with account: Account) throws {
    self.account = account
    
    // Create a connection to the server
    let connection = ServerConnection(descriptor: descriptor, locale: resourcePack.getDefaultLocale(), eventBus: eventBus)
    connection.setPacketHandler { [weak self] packet in
      guard let self = self else { return }
      self.handlePacket(packet)
    }
    try connection.login(username: account.username)
    self.connection = connection
  }
  
  /// Disconnect from the currently connected server if any.
  public func disconnect() {
    // Close connection
    connection?.close()
    connection = nil
    // Reset chunk storage
    game.changeWorld(to: World(eventBus: eventBus))
    // Stop ticking
    game.tickScheduler.cancel()
  }
  
  // MARK: Networking
  
  /// Send a packet to the server currently connected to (if any).
  public func sendPacket(_ packet: ServerboundPacket) throws {
    try connection?.sendPacket(packet)
  }
  
  /// The client's packet handler.
  public func handlePacket(_ packet: ClientboundPacket) {
    do {
      try packet.handle(for: self)
    } catch {
      disconnect()
      log.error("Failed to handle packet: \(error)")
      eventBus.dispatch(PacketHandlingErrorEvent(packetId: type(of: packet).id, error: "\(error)"))
    }
  }
  
  // MARK: Input
  
  /// Handles a key press.
  /// - Parameter input: The key to press.
  public func press(_ input: Input) {
    game.press(input)
    eventBus.dispatch(InputEvent.press(input))
  }
  
  /// Handles a key release.
  /// - Parameter input: The key to release.
  public func release(_ input: Input) {
    game.release(input)
    eventBus.dispatch(InputEvent.release(input))
  }
  
  /// Moves the mouse.
  /// - Parameters:
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(_ deltaX: Float, _ deltaY: Float) {
    game.moveMouse(deltaX, deltaY)
  }
}
