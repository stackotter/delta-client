import Foundation
import Network

/// An error that occured during LAN server enumeration.
enum LANServerEnumeratorError: LocalizedError {
  /// Failed to create the multicast group descriptor for the group that LAN servers broadcast on.
  case failedToCreateMulticastGroup(Error)
  /// Failed to connect to the multicast group that LAN servers broadcast on.
  case connectionFailed(NWError)
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
  
  /// Multicast connection group for receiving packets.
  private let group: NWConnectionGroup
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
    
    // Create multicast group
    let multicast: NWMulticastGroup
    do {
      multicast = try NWMulticastGroup(
        for: [.hostPort(host: "224.0.2.60", port: 4445)],
        disableUnicast: false)
    } catch {
      throw LANServerEnumeratorError.failedToCreateMulticastGroup(error)
    }
    
    group = NWConnectionGroup(with: multicast, using: .udp)
    
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
      let motd = messageContent.slice(from: "[MOTD]", to: "[/MOTD]"),
      var portString = messageContent.slice(from: "[AD]", to: "[/AD]")
    else {
      return
    }
    
    let hostString = String(describing: host)
    
    // If it's a full address, extract just the port
    if portString.contains(":") {
      portString = String(portString.split(separator: ":")[1])
    }
    
    // Parse the port into an unsigned short
    guard let port = UInt16(portString) else {
      log.warning("Invalid port in LAN server broadcast packet: \(portString)")
      return
    }
    
    // Create server descriptor
    log.trace("Received LAN server multicast packet: motd=`\(motd)`, address=`\(hostString):\(portString)`")
    let server = ServerDescriptor(name: motd, host: hostString, port: port)
    
    // If the server has already been discovered there's no need to handle it again
    guard !servers.contains(server) else {
      return
    }
    
    // Ping the server
    let pinger = Pinger(server)
    pinger.ping()
    servers.append(server)
    
    ThreadUtil.runInMain {
      print("Adding pinger")
      pingers.append(pinger)
    }
  }
}
