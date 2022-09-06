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
  public var configuration = ClientConfiguration() {
    didSet {
      guard connection?.hasJoined == true else {
        return
      }

      // Send update to server if connected
      do {
        try connection?.sendPacket(ClientSettingsPacket(configuration))
      } catch {
        eventBus.dispatch(ErrorEvent(error: error, message: "Failed to send client configuration update"))
      }
    }
  }

  /// The connection to the current server.
  public var connection: ServerConnection?
  /// An event bus shared with ``game``.
  public var eventBus = EventBus()
  /// Whether the client has finished downloading terrain yet.
  public var hasFinishedDownloadingTerrain = false

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
    let connection = ServerConnection(
      descriptor: descriptor,
      eventBus: eventBus
    )
    connection.setPacketHandler { [weak self] packet in
      guard let self = self else { return }
      self.handlePacket(packet)
    }
    game = Game(eventBus: eventBus, connection: connection)
    hasFinishedDownloadingTerrain = false
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
      if let entityPacket = packet as? ClientboundEntityPacket {
        game.handleDuringTick(entityPacket, client: self)
      } else {
        try packet.handle(for: self)
      }
    } catch {
      disconnect()
      log.error("Failed to handle packet: \(error)")
      eventBus.dispatch(PacketHandlingErrorEvent(packetId: type(of: packet).id, error: "\(error)"))
    }
  }

  // MARK: Input

  /// Handles a key press.
  /// - Parameters:
  ///   - key: The pressed key.
  ///   - characters: The characters typed by pressing the key.
  public func press(_ key: Key, _ characters: [Character] = []) {
    let input = configuration.keymap.getInput(for: key)
    game.press(key: key, input: input, characters: characters)
  }

  /// Handles an input press.
  /// - Parameter input: The pressed input.
  public func press(_ input: Input) {
    game.press(key: nil, input: input)
  }

  /// Handles a key release.
  /// - Parameter key: The released key.
  public func release(_ key: Key) {
    let input = configuration.keymap.getInput(for: key)
    game.release(key: key, input: input)
  }

  /// Handles an input release.
  /// - Parameter input: The released input.
  public func release(_ input: Input) {
    game.release(key: nil, input: input)
  }

  /// Moves the mouse.
  /// - Parameters:
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(_ deltaX: Float, _ deltaY: Float) {
    game.moveMouse(deltaX, deltaY)
  }
}
