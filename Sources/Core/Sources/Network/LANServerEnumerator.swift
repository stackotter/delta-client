import Foundation
import Parsing

#if !canImport(Combine)
import OpenCombine
#endif

/// An error that occured during LAN server enumeration.
enum LANServerEnumeratorError: LocalizedError {
  /// Failed to create multicast receiving socket.
  case failedToCreateMulticastSocket(Error)
  /// Failed to read from multicast socket.
  case failedToReadFromSocket(Error)

  var errorDescription: String? {
    switch self {
      case .failedToCreateMulticastSocket(let error):
        return """
        Failed to create multicast receiving socket for LAN server enumerator
        Reason: \(error.localizedDescription)
        """
      case .failedToReadFromSocket(let error):
        return """
        Failed to read from multicast socket for LAN server enumerator
        Reason: \(error.localizedDescription)
        """
    }
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

  /// Multicast socket for receiving packets.
  private var socket: Socket?
  /// Whether the enumerator is listening already or not.
  private var isListening = false

  /// Used to notify about errors.
  private let eventBus: EventBus
  /// Dispatch queue used for networking.
  private let queue = DispatchQueue(label: "LANServerEnumerator")

  // MARK: Init

  /// Creates a new LAN server enumerator.
  ///
  /// To start enumeration call `start`.
  /// - Parameter eventBus: Event bus to dispatch errors to.
  public init(eventBus: EventBus) {
    self.eventBus = eventBus
  }

  deinit {
    try? socket?.close()
  }

  /// Creates a new multicast socket for this instance to use for receiving broadcasts from servers
  /// on the local network..
  public func createSocket() throws {
    do {
      let socket = try Socket(.ip4, .udp)
      try socket.setValue(true, for: BoolSocketOption.localAddressReuse)
      try socket.bind(to: Socket.Address.ip4("224.0.2.60", 4445))

      try socket.setValue(
        try MembershipRequest(
          groupAddress: "224.0.2.60",
          localAddress: "0.0.0.0"
        ),
        for: MembershipRequestSocketOption.addMembership
      )

      self.socket = socket
    } catch {
      throw LANServerEnumeratorError.failedToCreateMulticastSocket(error)
    }
  }

  /// An async read loop that receives and parses messages from servers on the local network.
  ///
  /// It is implemented recursively to prevent the method from creating a reference cycle
  /// (by dropping self temporarily each iteration).
  public func asyncSocketReadLoop() {
    queue.async { [weak self] in
      guard let self = self, let socket = self.socket else {
        return
      }

      do {
        let (content, sender) = try socket.recvFrom(atMost: 16384)
        self.handlePacket(sender: sender, content: content)
      } catch {
        ThreadUtil.runInMain {
          self.hasErrored = true
        }
        self.eventBus.dispatch(
          ErrorEvent(
            error: LANServerEnumeratorError.failedToReadFromSocket(error),
            message: "LAN server enumeration failed"
          )
        )
        return
      }

      self.asyncSocketReadLoop()
    }
  }

  // MARK: Public methods

  /// Starts listening for LAN servers announcing themselves.
  public func start() throws {
    if socket == nil {
      try createSocket()
      asyncSocketReadLoop()
      isListening = true
    } else {
      log.warning("Attempted to start LANServerEnumerator twice")
    }
  }

  /// Stops scanning for new LAN servers and closes the multicast socket. Any pings that are in progress will still be completed.
  public func stop() {
    if isListening {
      try? socket?.close()
      socket = nil
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
  private func handlePacket(sender: Socket.Address, content: [UInt8]) {
    // Cap the maximum number of LAN servers that can be discovered
    guard servers.count < Self.maximumServerCount else {
      return
    }

    // Extract motd and port
    guard
      let content = String(bytes: content, encoding: .utf8),
      case let .ip4(host, _) = sender,
      let (motd, port) = parseMessage(content)
    else {
      log.error("Failed to parse LAN server broadcast message")
      return
    }

    let server = ServerDescriptor(name: motd, host: host, port: port)
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

    log.trace("Received LAN server multicast packet: motd=`\(motd)`, address=`\(host):\(port)`")
  }

  /// Parses a message of the form `"[MOTD]motd[/MOTD][AD]port[/AD]"`.
  /// - Parameter message: The message to parse.
  /// - Returns: The motd and port.
  private func parseMessage(_ message: String) -> (String, UInt16)? {
    let portParser = OneOf<Substring, _, _> {
      // Sometimes the port also includes a host ("host:port") so we must handle that case
      Parse {
        Prefix { $0 != ":" }
        ":"
        UInt16.parser()
      }.map { $0.1 }

      // Otherwise it's just a port
      UInt16.parser()
    }

    let packetParser = Parse<Substring, _> {
      "[MOTD]"
      Prefix { $0 != "["}
      "[/MOTD][AD]"
      portParser
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
