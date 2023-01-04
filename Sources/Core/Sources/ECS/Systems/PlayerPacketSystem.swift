import FirebladeECS
import FirebladeMath

/// Sends update packets to the server depending on which client and player properties have changed.
/// Mostly sends movement packets.
public struct PlayerPacketSystem: System {
  var connection: ServerConnection

  var state = State()

  class State {
    var previousHotbarSlot = -1
    var wasSprinting = false
    var wasSneaking = false
    var wasFlying = false
    var ticksUntilForcedPositionUpdate = 20
    var lastPositionSent = Vec3d.zero
  }

  public init(_ connection: ServerConnection) {
    self.connection = connection
  }

  public func update(_ nexus: Nexus, _ world: World) throws {
    guard connection.hasJoined else {
      return
    }

    var family = nexus.family(
      requiresAll: PlayerInventory.self,
      EntityId.self,
      EntitySprinting.self,
      EntitySneaking.self,
      EntityPosition.self,
      EntityRotation.self,
      EntityOnGround.self,
      EntityFlying.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (inventory, entityId, sprinting, sneaking, position, rotation, onGround, flying, _) = family.next() else {
      log.error("PlayerPacketSystem failed to get player to tick")
      return
    }

    // Send hotbar slot update
    if inventory.selectedHotbarSlot != state.previousHotbarSlot {
      try connection.sendPacket(HeldItemChangeServerboundPacket(slot: Int16(inventory.selectedHotbarSlot)))
      state.previousHotbarSlot = inventory.selectedHotbarSlot
    }

    // Send sprinting update
    let isSprinting = sprinting.isSprinting
    if isSprinting != state.wasSprinting {
      try connection.sendPacket(EntityActionPacket(
        entityId: Int32(entityId.id),
        action: isSprinting ? .startSprinting : .stopSprinting
      ))
      state.wasSprinting = isSprinting
    }

    // Send sneaking update
    let isSneaking = sneaking.isSneaking
    if isSneaking != state.wasSneaking {
      try connection.sendPacket(EntityActionPacket(
        entityId: Int32(entityId.id),
        action: isSneaking ? .startSneaking : .stopSneaking
      ))
      state.wasSneaking = isSneaking
    }

    // Send position update if player has moved fast enough
    let positionDelta = (position.vector - state.lastPositionSent).magnitudeSquared
    state.ticksUntilForcedPositionUpdate -= 1
    let mustSendPositionUpdate = positionDelta > 0.0009 || state.ticksUntilForcedPositionUpdate == 0
    let hasRotated = rotation.previousPitch != rotation.pitch || rotation.previousYaw != rotation.yaw
    var positionUpdateSent = true
    if mustSendPositionUpdate && hasRotated {
      try connection.sendPacket(PlayerPositionAndRotationServerboundPacket(
        position: position.vector,
        yaw: MathUtil.degrees(from: rotation.yaw),
        pitch: MathUtil.degrees(from: rotation.pitch),
        onGround: onGround.onGround
      ))
    } else if mustSendPositionUpdate {
      try connection.sendPacket(PlayerPositionPacket(
        position: position.vector,
        onGround: onGround.onGround
      ))
    } else if hasRotated {
      try connection.sendPacket(PlayerRotationPacket(
        yaw: MathUtil.degrees(from: rotation.yaw),
        pitch: MathUtil.degrees(from: rotation.pitch),
        onGround: onGround.onGround
      ))
    } else if onGround.onGround != onGround.previousOnGround {
      try connection.sendPacket(PlayerMovementPacket(onGround: onGround.onGround))
    } else {
      positionUpdateSent = false
    }

    if flying.isFlying != state.wasFlying {
      state.wasFlying = flying.isFlying
      try connection.sendPacket(PlayerAbilitiesServerboundPacket(flags: flying.isFlying ? [.flying] : []))
    }

    if positionUpdateSent {
      state.ticksUntilForcedPositionUpdate = 20
      state.lastPositionSent = position.vector
    }
  }
}
