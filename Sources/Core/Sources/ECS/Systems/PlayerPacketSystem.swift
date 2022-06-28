import FirebladeECS

public struct PlayerPacketSystem: System {
  var connection: ServerConnection

  var state = State()

  class State {
    var previousHotbarSlot = -1
  }

  public init(_ connection: ServerConnection) {
    self.connection = connection
  }

  public func update(_ nexus: Nexus, _ world: World) throws {
    var family = nexus.family(
      requiresAll: PlayerInventory.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (inventory, _) = family.next() else {
      log.error("PlayerPacketSystem failed to get player to tick")
      return
    }

    if inventory.hotbarSlot != state.previousHotbarSlot {
      try connection.sendPacket(HeldItemChangeServerboundPacket(slot: Int16(inventory.hotbarSlot)))
      state.previousHotbarSlot = inventory.hotbarSlot
    }
  }
}
