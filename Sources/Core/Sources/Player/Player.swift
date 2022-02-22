import FirebladeECS
import Foundation

/// Allows easy access to the player's components.
///
/// Please note that all components are classes.
public struct Player {
  /// The component storing the player's entity id.
  public private(set) var entityId: EntityId
  /// The component storing whether the player is on the ground/swimming or not.
  public private(set) var onGround: EntityOnGround
  /// The component storing the player's current experience level.
  public private(set) var experience: EntityExperience
  /// The component storing whether the player is flying.
  public private(set) var flying: EntityFlying
  /// The component storing the player's health.
  public private(set) var health: EntityHealth
  /// The component storing the player's hunger and saturation.
  public private(set) var nutrition: EntityNutrition
  /// The component storing the player's position.
  public private(set) var position: EntityPosition
  /// The component storing the player's velocity.
  public private(set) var velocity: EntityVelocity
  /// The component storing the plyaer's hit box.
  public private(set) var hitBox: EntityHitBox
  /// The component storing the player's rotation.
  public private(set) var rotation: EntityRotation
  /// The component storing the player's camera properties (does not include any settings such as fov that affect all entities).
  public private(set) var camera: EntityCamera
  /// The component storing the player's miscellaneous attributes.
  public private(set) var attributes: PlayerAttributes
  /// The component storing the player's gamemode related information.
  public private(set) var gamemode: PlayerGamemode
  /// The component storing the player's inventory.
  public private(set) var inventory: PlayerInventory
  
  /// Creates a player.
  public init() {
    let playerEntity = RegistryStore.shared.entityRegistry.playerEntityKind
    entityId = EntityId(-1) // Temporary value until the actual id is received from the server.
    onGround = EntityOnGround(true)
    position = EntityPosition(0, 0, 0, smoothingAmount: 1 / 18) // Having it set to slightly more than a tick smooths out any hick ups caused by late ticks
    rotation = EntityRotation(pitch: 0.0, yaw: 0.0, smoothingAmount: 1 / 18)
    velocity = EntityVelocity(0, 0.0, 0)
    hitBox = EntityHitBox(width: playerEntity.width, height: playerEntity.height)
    experience = EntityExperience()
    flying = EntityFlying()
    health = EntityHealth()
    nutrition = EntityNutrition()
    attributes = PlayerAttributes()
    camera = EntityCamera()
    gamemode = PlayerGamemode()
    inventory = PlayerInventory()
  }
  
  /// Adds the player to a game.
  /// - Parameter nexus: The game to create the player's entity in.
  public mutating func add(to game: inout Game) {
    game.createEntity(id: -1) {
      LivingEntity() // Mark it as a living entity
      PlayerEntity() // Mark it as a player
      ClientPlayerEntity() // Mark it as the current player
      EntityKindId(RegistryStore.shared.entityRegistry.playerEntityKindId) // Give it the entity kind id for player
      entityId
      onGround
      position
      rotation
      velocity
      hitBox
      experience
      flying
      health
      nutrition
      attributes
      camera
      gamemode
      inventory
    }
  }
}
