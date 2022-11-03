import Foundation

/// The network stack that handles receiving and sending Minecraft packets.
///
/// See https://wiki.vg/Protocol#Packet_format for more information about the packet format.
/// See https://wiki.vg/Protocol_Encryption for more in-depth information about packet encryption and decryption.
public final class NetworkStack {
  // MARK: Public properties

  /// The handler for packets received from the server.
  public var packetHandler: ((PacketReader) -> Void)?

  /// Handles the connection to the server (the raw network IO).
  public var socketLayer: SocketLayer
  /// Encrypts and decrypts packets.
  public var encryptionLayer: EncryptionLayer
  /// Compresses and decompresses packets.
  public var compressionLayer: CompressionLayer
  /// Splits the stream of bytes into individual Minecraft packets.
  public var packetLayer: PacketLayer

  /// The serial queue that outbound packets are handled on.
  public var outboundThread: DispatchQueue
  /// The serial queue that inbound packets are handled on.
  public var inboundThread: DispatchQueue

  // MARK: Private properties

  /// The host being connected to.
  private var host: String
  /// The port being connected to.
  private var port: UInt16
  /// The event bus that network errors are dispatched to.
  private var eventBus: EventBus

  // MARK: Init

  /// Creates a new network stack for connecting to the given server.
  public init(_ host: String, _ port: UInt16, eventBus: EventBus) {
    self.host = host
    self.port = port
    self.eventBus = eventBus

    // Create threads
    inboundThread = DispatchQueue(label: "NetworkStack.inboundThread")
    outboundThread = DispatchQueue(label: "NetworkStack.outboundThread")

    // Create layers
    socketLayer = SocketLayer(host, port, eventBus: eventBus)
    encryptionLayer = EncryptionLayer()
    compressionLayer = CompressionLayer()
    packetLayer = PacketLayer()

    // Setup handler for packets received from the server
    socketLayer.packetHandler = { [weak self] buffer in
      guard let self = self else { return }
      self.inboundThread.async {
        var buffer = buffer
        do {
          buffer = try self.encryptionLayer.processInbound(buffer)
          let buffers = try self.packetLayer.processInbound(buffer)

          for buffer in buffers {
            let buffer = try self.compressionLayer.processInbound(buffer)
            let packetReader = try PacketReader(buffer: buffer)
            log.trace("Packet received, id=0x\(String(format: "%02x", packetReader.packetId))")
            self.packetHandler?(packetReader)
          }
        } catch {
          log.warning("Failed to decode a packet received from the server: \(error)")
          self.socketLayer.disconnect()
          self.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to decode a packet received from the server"))
        }
      }
    }
  }

  // MARK: Public methods

  /// Sends a packet. Throws if the packet failed to be encrypted.
  public func sendPacket(_ packet: ServerboundPacket) throws {
    var buffer = packet.toBuffer()
    buffer = compressionLayer.processOutbound(buffer)
    buffer = packetLayer.processOutbound(buffer)
    buffer = try encryptionLayer.processOutbound(buffer)
    try socketLayer.send(buffer)
    log.trace("Packet sent, id=0x\(String(format: "%02x", type(of: packet).id))")
  }

  /// Connect to the server.
  public func connect() throws {
    let handler = socketLayer.packetHandler
    socketLayer = SocketLayer(host, port, eventBus: eventBus)
    socketLayer.packetHandler = handler

    compressionLayer = CompressionLayer()
    encryptionLayer = EncryptionLayer()
    packetLayer = PacketLayer()

    try socketLayer.connect()
  }

  /// Disconnect from the server.
  public func disconnect() {
    socketLayer.disconnect()
  }

  /// Reconnect to the server.
  public func reconnect() throws {
    disconnect()
    try connect()
  }
}
