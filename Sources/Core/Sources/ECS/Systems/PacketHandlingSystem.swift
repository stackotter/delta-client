import FirebladeECS

/// Handles all packets in the ``ClientboundEntityPacketStore``. Mostly the packets in the store are
/// entity movement packets. Handling them during the game tick helps position smoothing work
/// better.
public struct EntityPacketHandlingSystem: System {
  public func update(_ nexus: Nexus, _ world: World) throws {
    let packetStore = nexus.single(ClientboundEntityPacketStore.self).component
    do {
      try packetStore.handleAll()
    } catch {
      log.error("Failed to handle entity-related packets during tick: \(error)")
      throw error
    }
  }
}
