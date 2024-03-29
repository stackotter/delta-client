import FirebladeECS

public struct PlayerSmoothingSystem: System {
  public func update(_ nexus: Nexus, _ world: World) {
    var family = nexus.family(
      requiresAll: EntityPosition.self,
      EntityRotation.self,
      EntityOnGround.self,
      ClientPlayerEntity.self
    ).makeIterator()
    
    guard let (position, rotation, onGround, _) = family.next() else {
      log.error("PlayerSmoothingSystem failed to get player to tick")
      return
    }
    
    position.save()
    rotation.save()
    onGround.save()
  }
}
