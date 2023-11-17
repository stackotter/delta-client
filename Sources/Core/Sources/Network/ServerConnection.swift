import Foundation
import Resolver

public enum ServerConnectionError: LocalizedError {
  case invalidPacketId(Int)
  case failedToResolveHostname(hostname: String, Error?)

  public var errorDescription: String? {
    switch self {
      case .invalidPacketId(let id):
        return "Invalid packet id 0x\(String(id, radix: 16))."
      case .failedToResolveHostname(let hostname, let error):
        return """
        Failed to resolve hostname.
        Hostname: \(hostname)
        Reason: \(error?.localizedDescription ?? "unknown")
        """
    }
  }
}

public class ServerConnection {
  public private(set) var host: String
  public private(set) var ipAddress: String
  public private(set) var port: UInt16

  public var networkStack: NetworkStack

  public var packetRegistry: PacketRegistry
  public private(set) var state: State = .idle

  public private(set) var eventBus: EventBus

  public var version = ProtocolVersion.v1_16_1

  /// `true` if the ``JoinGamePacket`` has been received.
  public var hasJoined = false

  /// The string representation of the socket this connection is connecting to.
  public var socketAddress: String {
    return "\(host):\(port)"
  }

  // MARK: Init

  /// Create a new connection to the specified server.
  public init(descriptor: ServerDescriptor, eventBus: EventBus? = nil) throws {
    let (ipAddress, port) = try ServerConnection.resolve(descriptor)

    host = descriptor.host
    self.ipAddress = host
    self.port = port

    self.eventBus = eventBus ?? EventBus()
    packetRegistry = PacketRegistry.create_1_16_1()
    networkStack = NetworkStack(ipAddress, port, eventBus: self.eventBus)
  }

  // MARK: Lifecycle

  /// Closes the connection.
  public func close() {
    networkStack.disconnect()
    state = .disconnected
  }

  /// Restarts the connection to the server. Initiates the connection if not currently connected.
  private func restart() throws {
    state = .connecting
    try networkStack.reconnect()
  }

  /// Sets the state of the server connection.
  public func setState(_ newState: State) {
    state = newState
  }

  // MARK: NetworkStack configuration

  /// Sets the threshold required to compress a packet. Be careful, this isn't threadsafe.
  public func setCompression(threshold: Int) {
    networkStack.compressionLayer.compressionThreshold = threshold
  }

  /// Enables the packet encryption layer.
  public func enableEncryption(sharedSecret: [UInt8]) throws {
    try networkStack.encryptionLayer.enableEncryption(sharedSecret: sharedSecret)
  }

  // MARK: Packet

  /// Sets the handler to use for received packets.
  public func setPacketHandler(_ handler: @escaping (ClientboundPacket) -> Void) {
    networkStack.packetHandler = { [weak self] packetReader in
      guard let self = self else { return }
      do {
        if let packetState = self.state.packetState {
          // Create a mutable packet reader
          var reader = packetReader

          // Get the correct type of packet
          guard let packetType = self.packetRegistry.getClientboundPacketType(
            withId: reader.packetId,
            andState: packetState
          ) else {
            self.eventBus.dispatch(PacketDecodingErrorEvent(
              packetId: packetReader.packetId,
              error: "Invalid packet id 0x\(String(reader.packetId, radix: 16))"
            ))
            log.warning("Non-existent packet received with id 0x\(String(reader.packetId, radix: 16))")
            self.close()
            return
          }

          // Read the packet and then run its handler
          let packet = try packetType.init(from: &reader)
          handler(packet)
        }
      } catch {
        self.close()
        self.eventBus.dispatch(PacketDecodingErrorEvent(packetId: packetReader.packetId, error: "\(error)"))
        log.warning("Failed to decode packet with id \(String(packetReader.packetId, radix: 16)): \(error)")
      }
    }
  }

  /// Resolves a server descriptor into an IP and a port.
  public static func resolve(_ server: ServerDescriptor) throws -> (String, UInt16) {
    do {
      // We only care about IPv4
      var isIp: Bool
      let parts = server.host.split(separator: ".")
      if parts.count != 4 {
        isIp = false
      } else {
        isIp = true
        for part in parts {
          if UInt(part) == nil || part.count > 3 {
            isIp = false
            break
          }
        }
      }

      guard !isIp else {
        return (server.host, server.port ?? 25565)
      }

      // If `host` is an ip already, no need to perform DNS lookups
      let resolver = Resolver(timeout: 10)

      // Check for SRV records if no port is specified
      if server.port == nil {
        let records = try? resolver.discover("_minecraft._tcp.\(server.host)")
        if let record = records?.first {
          return (record.address, record.port.map(UInt16.init) ?? server.port ?? 25565)
        }
      }

      // Check for regular records
      let records = try resolver.resolve(server.host)
      if let record = records.first {
        return (record.address, server.port ?? 25565)
      }

      throw ServerConnectionError.failedToResolveHostname(hostname: server.host, nil)
    } catch {
      throw ServerConnectionError.failedToResolveHostname(hostname: server.host, error)
    }
  }

  /// Sends a packet to the server.
  /// - Parameter packet: The packet to send.
  public func sendPacket(_ packet: ServerboundPacket) throws {
    try networkStack.sendPacket(packet)
  }

  // MARK: Handshake

  /// Sends a login request to the server. Throws if the packet fails to send.
  /// - Parameter username: The username to login with.
  public func login(username: String) throws {
    try restart()

    try handshake(nextState: .login)
    let loginStart = LoginStartPacket(username: username)
    try sendPacket(loginStart)
  }

  /// Sends a status request or 'ping'.
  public func ping() throws {
    try restart()

    try handshake(nextState: .status)
    let statusRequest = StatusRequestPacket()
    try sendPacket(statusRequest)
  }

  /// Sends a handshake with the goal of transitioning to the given state (either status or login).
  public func handshake(nextState: HandshakePacket.NextState) throws {
    let handshake = HandshakePacket(protocolVersion: Constants.protocolVersion, serverAddr: host, serverPort: Int(port), nextState: nextState)
    try sendPacket(handshake)
    state = (nextState == .login) ? .login : .status
  }
}
