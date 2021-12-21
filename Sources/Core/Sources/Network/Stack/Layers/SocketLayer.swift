import Foundation
import Network

/// The network layer that handles a socket connection to a server.
///
/// Call ``connect()`` to start the socket connection. After connecting,
/// ``receive()`` can be called to start the receive loop. ``packetHandler``
/// will be called for each received packet.
public final class SocketLayer {
  // MARK: Public properties
  
  /// Called for each packet received.
  public var packetHandler: ((Buffer) -> Void)?
  
  // MARK: Private properties
  
  /// The queue for receiving packets on.
  private var ioQueue: DispatchQueue
  /// The event bus to dispatch network errors on.
  private var eventBus: EventBus
  
  /// A queue of packets waiting for the connection to start to be sent.
  private var packetQueue: [Buffer] = []
  
  /// The host being connected to.
  private var host: String
  /// The port being connected to.
  private var port: UInt16
  
  /// The socket connection to the server.
  private var connection: NWConnection
  /// The connection state of the socket.
  private var state: State = .idle
  
  /// A socket connection state.
  private enum State {
    case idle
    case connecting
    case connected
    case disconnected
  }
  
  // MARK: Init
  
  /// Creates a new socket layer for connecting to the given server.
  /// - Parameters:
  ///   - host: The host to connect to.
  ///   - port: The port to connect to.
  ///   - eventBus: The event bus to dispatch errors to.
  public init(
    _ host: String,
    _ port: UInt16,
    eventBus: EventBus
  ) {
    self.host = host
    self.port = port
    self.eventBus = eventBus
    
    guard let nwPort = NWEndpoint.Port(rawValue: port) else {
      fatalError("Failed to create port from int: \(port). This really shouldn't happen.")
    }
    
    ioQueue = DispatchQueue(label: "NetworkStack.ioThread")
    
    // Decrease the TCP timeout from the default
    let options = NWProtocolTCP.Options()
    options.connectionTimeout = 10
    self.connection = NWConnection(
      host: NWEndpoint.Host(host),
      port: nwPort,
      using: NWParameters(tls: nil, tcp: options))
    
    self.connection.stateUpdateHandler = { [weak self] newState in
      guard let self = self else { return }
      self.stateUpdateHandler(newState: newState)
    }
  }
  
  deinit {
    disconnect()
  }
  
  // MARK: Public methods
  
  /// Connect to the server.
  public func connect() {
    state = .connecting
    packetQueue = []
    connection.start(queue: ioQueue)
  }
  
  /// Disconnect from the server.
  public func disconnect() {
    state = .disconnected
    connection.cancel()
  }
  
  /// Starts the packet receiving loop.
  public func receive() {
    connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion: { [weak self] (data, _, _, error) in
      guard let self = self else { return }
      if let error = error {
        self.handleNWError(error)
        return
      } else if let data = data {
        let bytes = [UInt8](data)
        let buffer = Buffer(bytes)
        self.packetHandler?(buffer)
        
        if self.state != .disconnected {
          self.receive()
        }
      }
    })
  }
  
  /// Sends the given buffer to the connected server.
  ///
  /// If the connection is in a disconnected state, the packet is ignored. If the connection is
  /// idle or connecting, the packet is stored to be sent once a connection is established.
  /// - Parameter buffer: The buffer to send.
  public func send(_ buffer: Buffer) {
    switch state {
      case .connected:
        let bytes = buffer.bytes
        connection.send(content: Data(bytes), completion: .idempotent)
      case .idle, .connecting:
        packetQueue.append(buffer)
      case .disconnected:
        break
    }
  }
  
  // MARK: Private methods
  
  /// Handles a socket connection state update.
  /// - Parameter newState: The socket's new state.
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch newState {
      case .ready:
        state = .connected
        receive()
        for packet in packetQueue {
          send(packet)
        }
      case .waiting(let error):
        handleNWError(error)
      case .failed(let error):
        state = .disconnected
        handleNWError(error)
        eventBus.dispatch(ConnectionFailedEvent(networkError: error))
      case .cancelled:
        state = .disconnected
      default:
        break
    }
  }
  
  /// Handles a network error.
  /// - Parameter error: The error to handle.
  private func handleNWError(_ error: NWError) {
    if state != .disconnected {
      eventBus.dispatch(ConnectionFailedEvent(networkError: error))
      if error == NWError.posix(.ECONNREFUSED) {
        log.error("Connection refused: '\(self.host):\(self.port)'")
      } else if error == NWError.dns(-65554) {
        log.error("DNS failed for server at '\(self.host):\(self.port)'")
      }
    }
  }
}
