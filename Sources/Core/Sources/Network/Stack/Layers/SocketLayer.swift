import Foundation
import Network

public class SocketLayer: OutermostNetworkLayer {
  public var outboundSuccessor: OutboundNetworkLayer?
  public var inboundSuccessor: InboundNetworkLayer?
  
  private var inboundThread: DispatchQueue
  private var ioThread: DispatchQueue
  
  /// A queue of packets waiting to be sent. They are waiting for the connection to be ready.
  private var packetQueue: [Buffer] = []
  
  private var connection: NWConnection
  private var state: State = .idle
  
  private var host: String
  private var port: UInt16
  
  private var eventBus: EventBus
  
  public enum State {
    case idle
    case connecting
    case connected
    case disconnected
  }
  
  // MARK: Init
  
  public init(
    _ host: String,
    _ port: UInt16,
    inboundThread: DispatchQueue,
    ioThread: DispatchQueue,
    eventBus: EventBus
  ) {
    self.host = host
    self.port = port
    
    self.inboundThread = inboundThread
    self.ioThread = ioThread
    self.eventBus = eventBus
    
    guard let nwPort = NWEndpoint.Port(rawValue: port) else {
      fatalError("failed to create port from int: \(port). this really shouldn't happen")
    }
    
    // Decrease the TCP timeout from the default
    let options = NWProtocolTCP.Options()
    options.connectionTimeout = 10
    self.connection = NWConnection(
      host: NWEndpoint.Host(host),
      port: nwPort,
      using: NWParameters(tls: nil, tcp: options))
    
    self.connection.stateUpdateHandler = stateUpdateHandler
  }
  
  // MARK: Lifecycle
  
  public func connect() {
    state = .connecting
    packetQueue = []
    connection.start(queue: ioThread)
  }
  
  public func disconnect() {
    state = .disconnected
    connection.cancel()
  }
  
  // MARK: Inbound
  
  public func receive() {
    connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion: { (data, _, _, error) in
      if let error = error {
        self.handleNWError(error)
        return
      } else if let data = data {
        let bytes = [UInt8](data)
        let buffer = Buffer(bytes)
        
        self.inboundThread.async {
          let bufferCopy = buffer
          self.inboundSuccessor?.handleInbound(bufferCopy)
        }
        
        if self.state != .disconnected {
          self.receive()
        }
      }
    })
  }
  
  // MARK: Outbound
  
  public func handleOutbound(_ buffer: Buffer) {
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
  
  // MARK: Handlers
  
  private func stateUpdateHandler(newState: NWConnection.State) {
    switch newState {
      case .ready:
        state = .connected
        receive()
        packetQueue.forEach { packet in
          handleOutbound(packet)
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
  
  private func handleNWError(_ error: NWError) {
    eventBus.dispatch(ConnectionFailedEvent(networkError: error))
    if error == NWError.posix(.ECONNREFUSED) {
      log.error("Connection refused: '\(self.host):\(self.port)'")
    } else if error == NWError.dns(-65554) {
      log.error("Server at '\(self.host):\(self.port)' possibly uses SRV records (unsupported)")
    }
  }
}
