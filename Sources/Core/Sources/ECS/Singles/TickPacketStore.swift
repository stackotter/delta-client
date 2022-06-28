import FirebladeECS

/// Used to save tick packets until a tick occurs. Tick packets must be run during the game tick.
public final class TickPacketStore: SingleComponent {
  /// Packets are stored as closures to avoid systems needing access to the ``Client`` when running
  /// the packet handlers.
  public var packets: [() throws -> Void]

  /// Creates an empty store.
  public init() {
    packets = []
  }

  /// Adds a packet to be handled during the next tick.
  public func add(_ packet: ClientboundPacket, client: Client) {
    packets.append({ [weak client] in
      guard let client = client else { return }
      try packet.handle(for: client)
    })
  }

  /// Handles all stored packets and removes them.
  public func handleAll() throws {
    for packet in packets {
      try packet()
    }
    packets = []
  }
}
