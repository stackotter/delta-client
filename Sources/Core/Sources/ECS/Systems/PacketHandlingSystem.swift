import FirebladeECS

/// Handles all packets in the ``TickPacketStore``. Mostly the packets in the store are entity
/// movement packets. Handling them during the game tick helps position smoothing work better.
public struct PacketHandlingSystem: System {
  public func update(_ nexus: Nexus, _ world: World) throws {
    let packetStore = nexus.single(TickPacketStore.self).component
    do {
      try packetStore.handleAll()
    } catch {
      log.error("Failed to handle entity movement packets during tick: \(error)")
      throw error
    }
  }
}
