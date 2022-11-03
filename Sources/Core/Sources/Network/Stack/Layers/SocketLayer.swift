import Foundation
import FlyingSocks

/// An error thrown by ``SocketLayer``.
public enum SocketLayerError: LocalizedError {
  case failedToCreateSocket(Error)
  case alreadyConnected
  case noValidDNSRecords(String)

  public var errorDescription: String? {
    switch self {
      case .failedToCreateSocket(let error):
        return """
        Failed to create socket.
        Reason: \(error.localizedDescription)
        """
      case .alreadyConnected:
        return "An attempt to connect was made while already connected."
      case .noValidDNSRecords(let hostname):
        return "No valid DNS records for hostname '\(hostname)'."
    }
  }
}

/// The network layer that handles a socket connection to a server.
///
/// Call ``connect()`` to start the socket connection. After connecting,
/// ``receive()`` can be called to start the receive loop. ``packetHandler``
/// will be called for each received packet.
public final class SocketLayer {
  /// Called for each packet received.
  public var packetHandler: ((Buffer) -> Void)?

  /// The queue for receiving packets on.
  private var ioQueue: DispatchQueue
  /// The event bus to dispatch network errors on.
  private var eventBus: EventBus

  /// The IP address being connected to.
  private var ipAddress: String
  /// The port being connected to.
  private var port: UInt16

  /// A queue of packets waiting to be sent.
  private var packetQueue: [Buffer] = []

  /// The socket connection to the server.
  private var socket: Socket?
  /// The connection state of the socket.
  private var state: State = .idle

  /// A socket connection state.
  private enum State {
    case idle
    case connecting
    case connected
    case disconnected
  }

  /// Creates a new socket layer for connecting to the given server.
  /// - Parameters:
  ///   - ipAddress: The ip address to connect to.
  ///   - port: The port to connect to.
  ///   - eventBus: The event bus to dispatch errors to.
  public init(
    _ ipAddress: String,
    _ port: UInt16,
    eventBus: EventBus
  ) {
    self.ipAddress = ipAddress
    self.port = port
    self.eventBus = eventBus

    ioQueue = DispatchQueue(label: "NetworkStack.ioThread")
  }

  deinit {
    disconnect()
  }

  /// Creates the layer's socket connection synchronously.
  ///
  /// Once connected it sends all packets that were waiting to be sent until connected (stored in
  /// ``packetQueue``).
  private func createSocket() throws {
    do {
      // https://github.com/stackotter/delta-client/issues/151
      let address = try sockaddr_in.inet(
        ip4: ipAddress,
        port: port
      )
      let socket = try Socket(domain: Int32(address.makeStorage().ss_family), type: SOCK_STREAM)

      let timeout = TimeValue(seconds: 10)
      try socket.setValue(timeout, for: .sendTimeout)
      try socket.setValue(timeout, for: .receiveTimeout)
      try socket.connect(to: address)

      self.socket = socket
      state = .connected

      // Send any packets that were waiting for a connection
      for packet in packetQueue {
        try send(packet)
      }
      packetQueue = []
    } catch {
      throw SocketLayerError.failedToCreateSocket(error)
    }
  }

  /// Starts an asynchronous loop that receives and handles packets until disconnected or an error
  /// occurs. Implemented recursively to avoid creating reference cycles.
  private func asyncSocketReadLoop() {
    ioQueue.async { [weak self] in
      guard let self = self, let socket = self.socket else {
        return
      }

      do {
        let bytes = try socket.read(atMost: 4096)
        let buffer = Buffer(bytes)
        self.packetHandler?(buffer)

        if self.state != .disconnected {
          self.asyncSocketReadLoop()
        }
      } catch {
        if self.state == .disconnected {
          return
        }

        self.disconnect()
        self.eventBus.dispatch(ConnectionFailedEvent(networkError: error))
      }
    }
  }

  /// Connects to the server.
  public func connect() throws {
    packetQueue = []
    state = .connecting

    if socket == nil {
      ioQueue.async {
        do {
          try self.createSocket()
          self.asyncSocketReadLoop()
        } catch {
          self.disconnect()
          self.eventBus.dispatch(ConnectionFailedEvent(networkError: error))
        }
      }
    } else {
      throw SocketLayerError.alreadyConnected
    }
  }

  /// Disconnect from the server.
  public func disconnect() {
    state = .disconnected
    do {
      try socket?.close()
    } catch {
      log.warning("Failed to close socket gracefully")
    }
    socket = nil
  }

  /// Sends the given buffer to the connected server.
  ///
  /// If the connection is in a disconnected state, the packet is ignored. If the connection is
  /// idle or connecting, the packet is stored to be sent once a connection is established.
  /// - Parameter buffer: The buffer to send.
  public func send(_ buffer: Buffer) throws {
    guard state == .connected, let socket = socket else {
      packetQueue.append(buffer)
      return
    }

    let bytes = buffer.bytes
    _ = try socket.write(Data(bytes))
  }
}
