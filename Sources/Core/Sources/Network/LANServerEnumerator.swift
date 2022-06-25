import Foundation
import NIOPosix
import NIOCore
import Parsing

private final class MessageDecoder: ChannelInboundHandler {
  public typealias InboundIn = AddressedEnvelope<ByteBuffer>

  public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let enveloppe = self.unwrapInboundIn(data)
    var buffer = enveloppe.data

    guard let message = buffer.readString(length: buffer.readableBytes) else {
      print("Error")
      return
    }

    print("thing")
  }
}

private final class MessageEncoder: ChannelInboundHandler {
  public typealias OutboundIn = AddressedEnvelope<String>
  public typealias OutboundOut = AddressedEnvelope<ByteBuffer>

  func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
    let message = self.unwrapOutboundIn(data)
    let buffer = context.channel.allocator.buffer(capacity: message.data)
    context.write(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: message.remoteAddress, data: buffer)), promise: promise)
  }
}

/// Used to discover LAN servers (servers on the same network as the client).
///
/// LAN servers broadcast themselves through UDP multicast packets on the `224.0.2.60` multicast group
/// and port `4445`. They send messages of the form `[MOTD]username - world name[/MOTD][AD]port[/AD]`.
///
/// As well as discovering servers, the enumerator also pings them for more information (see ``pingers``).
///
/// Make sure to call ``stop()`` before trying to create another enumerator.
public class LANServerEnumerator: ObservableObject {
  // MARK: Static properties
  
  /// Used to prevent DoS attacks. 50 LAN servers at a time is definitely enough, in most cases there will be at most 2 or 3.
  public static let maximumServerCount = 50
  
  // MARK: Public properties
  
  /// Pingers for all currently identified LAN servers.
  @Published public var pingers: [Pinger] = []
  /// Whether the enumerator has errored or not.
  @Published public var hasErrored = false
  /// All currently identified servers.
  public var servers: [ServerDescriptor] = []
  
  // MARK: Private properties

  /// Whether the enumerator is listening already or not.
  private var isListening = false
  
  /// Used to notify about errors.
  private let eventBus: EventBus
  /// Dispatch queue used for networking.
  private let queue = DispatchQueue(label: "dev.stackotter.delta-client.LANServerEnumerator")
  
  // MARK: Init
  
  /// Creates a new LAN server enumerator.
  /// - Parameter eventBus: Event bus to dispatch errors to.
  public init(eventBus: EventBus) throws {
    self.eventBus = eventBus

    let multicast = try! SocketAddress(ipAddress: "224.0.2.60", port: 4445)
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    var datagramBootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .channelInitializer { channel in
      return channel.pipeline.addHandler(MessageEncoder()).flatmap {
        channel.pipeline.addHandler(MessageDecoder())
      }
    }

    // Handle packets
    group.setReceiveHandler(maximumMessageSize: 16384, rejectOversizedMessages: true) { [weak self] message, content, isComplete in
      guard let self = self else {
        return
      }
      
      self.handlePacket(message: message, content: content, isComplete: isComplete)
    }
    
    // Handle state updates
    group.stateUpdateHandler = { [weak self] newState in
      guard let self = self else {
        return
      }
      
      switch newState {
        case .failed(let error):
          ThreadUtil.runInMain {
            self.hasErrored = true
          }
          self.eventBus.dispatch(
            ErrorEvent(
              error: LANServerEnumeratorError.connectionFailed(error),
              message: "LAN server enumeration failed"
            ))
        case .cancelled:
          self.isListening = false
        default:
          break
      }
    }
  }
  
  // MARK: Public methods
  
  /// Starts listening for LAN servers announcing themselves.
  public func start() {
    if !isListening {
      group.start(queue: queue)
      isListening = true
    } else {
      log.warning("Attempted to start LANServerEnumerator twice")
    }
  }
  
  /// Stops scanning for new LAN servers and closes the multicast socket. Any pings that are in progress will still be completed.
  public func stop() {
    if isListening {
      group.cancel()
    } else {
      log.warning("Attempted to stop LANServerEnumerator while it wasn't started")
    }
  }
  
  /// Clears all currently discovered servers.
  public func clear() {
    servers = []
    ThreadUtil.runInMain {
      pingers = []
    }
  }
  
  // MARK: Private methods
  
  /// Parses LAN server multicast messages.
  ///
  /// They are expected to be of the form: `[MOTD]message of the day[/MOTD][AD]port[/AD]`.
  /// Apparently sometimes the entire address is included in the `AD` section so that is
  /// handled too.
  private func handlePacket(message: NWConnectionGroup.Message, content: Data?, isComplete: Bool) {
    // Cap the maximum number of LAN servers that can be discovered
    guard servers.count < Self.maximumServerCount else {
      return
    }
    
    // Extract motd and port
    guard
      let content = content,
      let messageContent = String(data: content, encoding: .utf8),
      case let .hostPort(host: host, port: _) = message.remoteEndpoint,
      let (motd, port) = parseMessage(messageContent)
    else {
      return
    }
    
    let hostString = String(describing: host)
    let server = ServerDescriptor(name: motd, host: hostString, port: port)
    if servers.contains(server) {
      return
    }
    
    // Ping the server
    let pinger = Pinger(server)
    try? pinger.ping()
    servers.append(server)
    
    ThreadUtil.runInMain {
      pingers.append(pinger)
    }
    
    log.trace("Received LAN server multicast packet: motd=`\(motd)`, address=`\(hostString):\(port)`")
  }
  
  /// Parses a message of the form `"[MOTD]motd[/MOTD][AD]port[/AD]"`.
  /// - Parameter message: The message to parse.
  /// - Returns: The motd and port.
  private func parseMessage(_ message: String) -> (String, UInt16)? {
    let packetParser = Parse {
      "[MOTD]"
      Prefix { $0 != "["}
      "[/MOTD][AD]"
      OneOf {
        // Sometimes the port also includes a host ("host:port") so we must handle that case
        Parse {
          Prefix { $0 != ":" }
          ":"
          UInt16.parser()
        }.map { $0.1 }
        
        // Otherwise it's just a port
        UInt16.parser()
      }
      "[/AD]"
    }.map { tuple -> (String, UInt16) in
      (String(tuple.0), tuple.1)
    }
    
    do {
      return try packetParser.parse(message)
    } catch {
      log.warning("Invalid LAN server broadcast message received: \"\(message)\", error: \(error)")
      return nil
    }
  }
}
