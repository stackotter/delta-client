import FirebladeECS
import Foundation

/// Information about the player. Allows easy access to the player's components.
public struct Player {
  public var entity: Entity
  
  public var experience: EntityExperience {
    get { entity.get(component: Box<EntityExperience>.self)!.value }
    set { entity.get(component: Box<EntityExperience>.self)!.value = newValue }
  }
  
  public var flying: EntityFlying {
    get { entity.get(component: Box<EntityFlying>.self)!.value }
    set { entity.get(component: Box<EntityFlying>.self)!.value = newValue }
  }
  
  public var health: EntityHealth {
    get { entity.get(component: Box<EntityHealth>.self)!.value }
    set { entity.get(component: Box<EntityHealth>.self)!.value = newValue }
  }
  
  public var nutrition: EntityNutrition {
    get { entity.get(component: Box<EntityNutrition>.self)!.value }
    set { entity.get(component: Box<EntityNutrition>.self)!.value = newValue }
  }
  
  /// The player's position, updated once per tick.
  public var position: EntityPosition {
    get { entity.get(component: Box<EntityPosition>.self)!.value }
    set {
      entity.get(component: Box<EntityPosition>.self)!.value = newValue
      targetPosition = EntityTargetPosition(position: newValue)
    }
  }
  
  /// The position the player will be at next tick.
  public var targetPosition: EntityTargetPosition {
    get { entity.get(component: Box<EntityTargetPosition>.self)!.value }
    set { entity.get(component: Box<EntityTargetPosition>.self)!.value = newValue }
  }
  
  public var rotation: EntityRotation {
    get { entity.get(component: Box<EntityRotation>.self)!.value }
    set { entity.get(component: Box<EntityRotation>.self)!.value = newValue }
  }
  
  public var velocity: EntityVelocity {
    get { entity.get(component: Box<EntityVelocity>.self)!.value }
    set { entity.get(component: Box<EntityVelocity>.self)!.value = newValue }
  }
  
  public var attributes: PlayerAttributes {
    get { entity.get(component: Box<PlayerAttributes>.self)!.value }
    set { entity.get(component: Box<PlayerAttributes>.self)!.value = newValue }
  }
  
  public var gamemode: PlayerGamemode {
    get { entity.get(component: Box<PlayerGamemode>.self)!.value }
    set { entity.get(component: Box<PlayerGamemode>.self)!.value = newValue }
  }
  
  public var inventory: PlayerInventory {
    get { entity.get(component: Box<PlayerInventory>.self)!.value }
    set { entity.get(component: Box<PlayerInventory>.self)!.value = newValue }
  }
  
  public var input: PlayerInput {
    get { entity.get(component: Box<PlayerInput>.self)!.value }
    set { entity.get(component: Box<PlayerInput>.self)!.value = newValue }
  }
  
  /// Creates the player.
  /// - Parameter nexus: The nexus to create the player's entity in.
  public init(_ nexus: Nexus) {
    entity = nexus.createEntity {
      Box(LivingEntity()) // Mark it as a living entity
      Box(ClientPlayerEntity()) // Mark it as the current player
      Box(PlayerEntity()) // Mark it as a player
      Box(EntityPosition(x: 0, y: 0, z: 0))
      Box(EntityTargetPosition(position: EntityPosition(x: 0, y: 0, z: 0)))
      Box(EntityRotation(pitch: 0.0, yaw: 0.0))
      Box(EntityVelocity(x: 0.0, y: 0.0, z: 0.0))
      Box(EntityExperience())
      Box(EntityFlying())
      Box(EntityHealth())
      Box(EntityNutrition())
      Box(PlayerAttributes())
      Box(PlayerGamemode())
      Box(PlayerInventory())
      Box(PlayerInput())
    }
  }
  
  /// Updates the direction the player is looking in with a mouse movement event.
  public mutating func updateLook(with event: MouseMoveEvent) {
    let sensitivity: Float = 0.35
    rotation.yaw += event.deltaX * sensitivity
    rotation.pitch += event.deltaY * sensitivity
    
    // Clamp pitch between -90 and 90
    rotation.pitch = min(max(-90, rotation.pitch), 90)
    // Wrap yaw to between 0 and 360
    let remainder = rotation.yaw.truncatingRemainder(dividingBy: 360)
    rotation.yaw = remainder < 0 ? 360 + remainder : remainder
  }
  
  /// Updates the player's velocity with an input event.
  public mutating func updateInputs(with event: InputEvent) {
    switch event.type {
      case .press:
        input.inputs.insert(event.input)
      case .release:
        input.inputs.remove(event.input)
    }
  }
}
