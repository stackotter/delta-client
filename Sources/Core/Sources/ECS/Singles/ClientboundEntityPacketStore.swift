import FirebladeECS

/// Used to save entity-related packets until a tick occurs. Entity packets must be handled during
/// the game tick.
public final class ClientboundEntityPacketStore: SingleComponent {
  /// Packets are stored as closures to avoid systems needing access to the ``Client`` when running
  /// the packet handlers.
  public var packets: [() throws -> Void]

  /// Creates an empty store.
  public init() {
    packets = []
  }

  /// Adds a packet to be handled during the next tick.
  public func add(_ packet: ClientboundEntityPacket, client: Client) {
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
