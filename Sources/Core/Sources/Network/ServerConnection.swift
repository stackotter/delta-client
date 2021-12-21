import Foundation
import Network
import NioDNS
import NIO

public class ServerConnection {
  public private(set) var host: String
  public private(set) var port: UInt16
  
  public var networkStack: NetworkStack
  
  public var packetRegistry: PacketRegistry
  public private(set) var state: State = .idle
  
  public private(set) var eventBus: EventBus
  
  public var version = ProtocolVersion.v1_16_1
  public var locale: MinecraftLocale
  
  /// The string representation of the socket this connection is connecting to.
  public var socketAddress: String {
    return "\(host):\(port)"
  }
  
  // MARK: Init
  
  /// Create a new connection to the specified server.
  public init(descriptor: ServerDescriptor, locale: MinecraftLocale? = nil, eventBus: EventBus? = nil) {
    let address = Self.resolve(descriptor)
    
    host = address.host
    port = address.port
    
    self.eventBus = eventBus ?? EventBus()
    packetRegistry = PacketRegistry.create_1_16_1()
    networkStack = NetworkStack(host, port, eventBus: self.eventBus)
    self.locale = locale ?? MinecraftLocale()
  }
  
  // MARK: Lifecycle
  
  /// Closes the connection.
  public func close() {
    networkStack.disconnect()
    state = .disconnected
  }
  
  /// Restarts the connection to the server. Initiates the connection if not currently connected.
  private func restart() {
    state = .connecting
    networkStack.reconnect()
  }
  
  /// Sets the state of the server connection.
  public func setState(_ newState: State) {
    state = newState
  }
  
  // MARK: DNS
  
  /// Converts a server descriptor to a socket address.
  ///
  /// If port is specified it just returns the host and port from the descriptor. Otherwise
  /// it checks for SRV records. And if nothing else, returns the default port `25565`.
  public static func resolve(_ descriptor: ServerDescriptor) -> (host: String, port: UInt16) {
    // If the port is specified we do nothing
    if let port = descriptor.port {
      return (descriptor.host, port)
    }
    
    // First we check for SRV records
    do {
      let loop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
      let client = try NioDNS.connect(on: loop).wait()
      
      let records = try client.getSRVRecords(from: "_minecraft._tcp.\(descriptor.host)").wait()
      for record in records {
        // Create a hostname from the bytes we're given. Iterators FTW
        let srvHostname = record.resource.domainName.map({
          $0.label.map({
            String(Character(UnicodeScalar($0)))
          }).joined()
        }).dropLast().joined(separator: ".")
        
        return (srvHostname, record.resource.port)
      }
    } catch {
      print("Failed to resolve SRV record")
    }
    
    // Return the default port
    return (descriptor.host, 25565)
  }
  
  // MARK: NetworkStack configuration
  
  /// Sets the threshold required to compress a packet.
  public func setCompression(threshold: Int) {
    networkStack.compressionLayer.compressionThreshold = threshold
  }
  
  /// Enables the packet encryption layer.
  public func enableEncryption(sharedSecret: [UInt8]) {
    networkStack.encryptionLayer.enableEncryption(sharedSecret: sharedSecret)
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
          reader.locale = self.locale
          
          // Get the correct type of packet
          guard let packetType = self.packetRegistry.getClientboundPacketType(withId: reader.packetId, andState: packetState) else {
            log.warning("Non-existent packet received with id 0x\(String(reader.packetId, radix: 16))")
            return
          }
          
          // Read the packet and then run its handler
          let packet = try packetType.init(from: &reader)
          handler(packet)
        }
      } catch {
        self.close()
        self.eventBus.dispatch(PacketDecodingErrorEvent(packetId: packetReader.packetId, error: "\(error.localizedDescription)"))
        log.warning("Failed to decode packet with id \(String(packetReader.packetId, radix: 16)): \(error.localizedDescription)")
      }
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
    restart()
    
    try handshake(nextState: .login)
    let loginStart = LoginStartPacket(username: username)
    try sendPacket(loginStart)
  }
  
  /// Sends a status request or 'ping'.
  public func ping() throws {
    restart()
    
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
