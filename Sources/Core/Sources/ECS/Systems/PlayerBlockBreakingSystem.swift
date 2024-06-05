import FirebladeECS

public final class PlayerBlockBreakingSystem: System {
  var connection: ServerConnection?
  weak var game: Game?
  var lastDestroyCompletionTick: Int?

  public init(_ connection: ServerConnection?, _ game: Game) {
    self.connection = connection
    self.game = game
  }

  public func update(_ nexus: Nexus, _ world: World) throws {
    guard let game = game else {
      return
    }

    // TODO: Cancel digging when hotbar slot changes

    var family = nexus.family(
      requiresAll: PlayerInventory.self,
      PlayerGamemode.self,
      PlayerAttributes.self,
      EntityId.self,
      ClientPlayerEntity.self
    ).makeIterator()

    guard let (inventory, gamemode, attributes, playerEntityId, _) = family.next() else {
      log.error("PlayerInputSystem failed to get player to tick")
      return
    }

    guard gamemode.gamemode.canPlaceBlocks else {
      return
    }

    let guiState = nexus.single(GUIStateStorage.self).component

    guard guiState.movementAllowed else {
      return
    }

    // 5tick delay between successfully breaking a block and starting to break the next one.
    if let completionTick = lastDestroyCompletionTick, game.tickScheduler.tickNumber - completionTick <= 5 {
      return
    }

    let inputState = nexus.single(InputState.self).component

    guard let targetedBlock = game.targetedBlock(acquireLock: false) else {
      if let block = world.getBreakingBlocks().first(where: { $0.perpetratorEntityId == playerEntityId.id }) {
        world.endBlockBreaking(for: playerEntityId.id)

        try self.connection?.sendPacket(PlayerDiggingPacket(
          status: .cancelledDigging,
          location: block.position,
          face: .up // TODO: Figure out what value to use in this situation
        ))
      }
      return
    }

    let position = targetedBlock.target

    let notifyServer = { status in
      try self.connection?.sendPacket(PlayerDiggingPacket(
        status: status,
        location: position,
        face: targetedBlock.face
      ))
    }

    guard !attributes.canInstantBreak else {
      if inputState.newlyPressed.contains(where: { $0.input == .destroy }) {
        try notifyServer(.startedDigging)
      }
      return
    }

    let newlyReleased = inputState.newlyReleased.contains(where: { $0.input == .destroy })
    if newlyReleased {
      world.endBlockBreaking(for: playerEntityId.id)
      try notifyServer(.cancelledDigging)
    }

    // Technically possible to release and press again within the same tick.
    if inputState.newlyPressed.contains(where: { $0.input == .destroy }) {
      world.startBreakingBlock(at: position, for: playerEntityId.id)
      try notifyServer(.startedDigging)
    } else if inputState.inputs.contains(.destroy) && !newlyReleased {
      let ourBreakingBlocks = world.getBreakingBlocks().filter { block in
        block.perpetratorEntityId == playerEntityId.id
      }

      var alreadyMiningTargetedBlock = false
      for block in ourBreakingBlocks {
        if block.position != position {
          world.endBlockBreaking(at: block.position)
          try notifyServer(.cancelledDigging)
        } else {
          alreadyMiningTargetedBlock = true
        }
      }

      if alreadyMiningTargetedBlock {
        // TODO: This may be off by one tick, worth double checking
        let block = world.getBlock(at: position)
        let heldItem = inventory.mainHandItem
        world.addBreakingProgress(Self.computeDestroyProgressDelta(block, heldItem), toBlockAt: position)
        let progress = world.getBlockBreakingProgress(at: position) ?? 0
        if progress >= 1 {
          world.endBlockBreaking(for: playerEntityId.id)
          world.setBlockId(at: position, to: 0)
          try notifyServer(.finishedDigging)
          lastDestroyCompletionTick = game.tickScheduler.tickNumber
        }
      } else {
        world.startBreakingBlock(at: position, for: playerEntityId.id)
        try notifyServer(.startedDigging)
      }
    }
  }

  public static func computeDestroyProgressDelta(_ block: Block, _ heldItem: Item?) -> Double {
    let isBamboo = block.className == "BambooBlock" || block.className == "BambooSaplingBlock"
    let holdingSword = heldItem?.properties?.toolProperties?.kind == .sword
    if isBamboo && holdingSword {
      return 1
    } else {
      let hardness = block.physicalMaterial.hardness

      // TODO: Sentinel values are gross, we could probably just make hardness an optional
      //   (don't have to copy vanilla). I would do that right now but we need cache versioning
      //   first cause I'm pretty sure that change is subtle enough that it might just crash cache
      //   loading instead of forcing it to fail and retry from pixlyzer.
      guard hardness != -1 else {
        return 0
      }

      let defaultSpeed = block.physicalMaterial.requiresTool ? 0.01 : (1 / 30)
      let toolSpeed = heldItem?.properties?.toolProperties?.destroySpeedMultiplier(for: block) ?? defaultSpeed
      return toolSpeed / hardness
    }
  }
}
