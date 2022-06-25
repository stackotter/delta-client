import Foundation
import NIOCore
import NIOPosix

private final class MessageHandler: ChannelInboundHandler {
  public typealias InboundIn = ByteBuffer
  public typealias OutboundOut = ByteBuffer
  private var sendBytes = 0
  private var receiveBuffer: ByteBuffer = ByteBuffer()

  public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    var buffer = self.unwrapInboundIn(data)
    while let byte: UInt8 = buffer.readInteger() {
      fputc(Int32(byte), stdout)
    }
  }
}

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
  private var connection: SocketAddress
  private var channel: Channel
  private var bootstrap: NIOClientTCPBootstrapProtocol

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

    ioQueue = DispatchQueue(label: "NetworkStack.ioThread")

    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.connectTimeout, value: ConnectTimeoutOption.Value(10))
            .channelInitializer { channel in
              channel.pipeline.addHandler(MessageHandler())
            }
  }

    deinit {
      try! disconnect()
    }


    // MARK: Public methods

    /// Connect to the server.
    public func connect() throws {
      channel = try bootstrap.connect(host: host, port: port).wait()
    }

    /// Disconnect from the server.
    public func disconnect() throws {
      try channel.close().wait()
    }

    /// Starts the packet receiving loop.
    public func receive() {
      connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion: { [weak self] (data, _, _, error) in
        guard let self = self else {
          return
        }
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
  }
