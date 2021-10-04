import Foundation
import simd

/// The current player (`PlayerEntity` is used for other players).
public struct Player {
  /// The player's spawn position.
  public private(set) var spawnPosition = Position(x: 0, y: 0, z: 0)
  /// The player's position.
  public private(set) var position = EntityPosition(x: 0, y: 0, z: 0)
  /// The player's velocity.
  public private(set) var velocity = SIMD3<Double>(repeating: 0)
  /// The player's rotation.
  public private(set) var look = PlayerRotation(yaw: 0, pitch: 0)
  
  /// The player's experience bar progress.
  public private(set) var experienceBarProgress: Float = 0
  /// The player's total xp.
  public private(set) var experience = 0
  /// The player's xp level (displayed above the xp bar).
  public private(set) var experienceLevel = 0
  /// The player's health.
  public private(set) var health: Float = 0
  /// The player's hunger.
  public private(set) var food = 0
  /// The player's saturation.
  public private(set) var saturation: Float = 0
  
  /// The player's currently selected hotbar slot.
  public private(set) var hotbarSlot: Int = 0
  /// The player's maximum flying speed (set by server).
  public private(set) var flyingSpeed: Float = 0
  /// The player's current fov modifier.
  public private(set) var fovModifier: Float = 0
  /// Whether the player is invulnerable to damage or not. In creative mode this is `true`.
  public private(set) var isInvulnerable = false
  /// Whether the player is flying or not.
  public private(set) var isFlying = false
  /// Whether the player is allowed to fly or not.
  public private(set) var canFly = false
  
  /// Whether the player is in creative mode or not. This is a weird Mojang quirk. Use `Player.gamemode` instead.
  public private(set) var creativeMode = false // enables insta break?
  /// The player's previous gamemode. Likely used in vanilla by the F3+F4 gamemode switcher.
  public private(set) var previousGamemode: Gamemode
  /// The player's gamemode.
  public private(set) var gamemode: Gamemode
  /// Whether the player is in hardcore mode or not. Affects respawn screen and rendering of hearts.
  public private(set) var isHardcore: Bool
  
  /// The current input events acting on the player
  public private(set) var currentInputs = Set<Input>()
  
  /// The player's eye position.
  public var eyePositon: EntityPosition {
    var eyePosition = position
    eyePosition.y += 1.625
    return eyePosition
  }
  
  /// Create a new player from a `JoinGamePacket`.
  public init(from packet: JoinGamePacket) {
    previousGamemode = packet.previousGamemode
    gamemode = packet.gamemode
    isHardcore = packet.isHardcore
  }
  
  // TODO: This method should not exist. All position updates should be done by the player eventually.
  public mutating func setPosition(to position: EntityPosition) {
    self.position = position
  }
  
  /// Changes the player's currently selected hotbar slot.
  public mutating func selectHotbarSlot(_ index: Int) {
    hotbarSlot = index
  }
  
  /// Updates the player's spawn position with a `SpawnPositionPacket`.
  public mutating func update(with packet: SpawnPositionPacket) {
    spawnPosition = packet.location
  }
  
  /// Updates the player's gamemode with a `RespawnPacket`.
  public mutating func update(with packet: RespawnPacket) {
    gamemode = packet.gamemode
    previousGamemode = packet.previousGamemode
  }
  
  /// Updates the player's experience with a `SetExperiencePacket`.
  public mutating func update(with packet: SetExperiencePacket) {
    experienceBarProgress = packet.experienceBar
    experienceLevel = packet.level
    experience = packet.totalExperience
  }
  
  /// Updates the player's health related stats with an `UpdateHealthPacket`.
  public mutating func update(with packet: UpdateHealthPacket) {
    health = packet.health
    food = packet.food
    saturation = packet.foodSaturation
  }
  
  /// Updates the player's modifiers and flags with a `PlayerAbilitiesPacket`.
  public mutating func update(with packet: PlayerAbilitiesPacket) {
    flyingSpeed = packet.flyingSpeed
    fovModifier = packet.fovModifier
    isInvulnerable = packet.flags.contains(.invulnerable)
    isFlying = packet.flags.contains(.flying)
    canFly = packet.flags.contains(.allowFlying)
    creativeMode = packet.flags.contains(.creativeMode)
  }
  
  /// Updates the player's position and look with a `PlayerPositionAndLookClientboundPacket`.
  public mutating func update(with packet: PlayerPositionAndLookClientboundPacket) {
    if packet.flags.contains(.x) {
      position.x += packet.position.x
    } else {
      position.x = packet.position.x
    }
    
    if packet.flags.contains(.y) {
      position.y += packet.position.y
    } else {
      position.y = packet.position.y
    }
    
    if packet.flags.contains(.z) {
      position.z += packet.position.z
    } else {
      position.z = packet.position.z
    }
    
    if packet.flags.contains(.yRot) {
      look.yaw += packet.yaw
    } else {
      look.yaw = packet.yaw
    }
    
    if packet.flags.contains(.xRot) {
      look.pitch += packet.pitch
    } else {
      look.pitch = packet.pitch
    }
  }
  
  /// Updates the direction the player is looking in with a mouse movement event.
  public mutating func updateLook(with event: MouseMoveEvent) {
    let sensitivity: Float = 0.35
    look.yaw += event.deltaX * sensitivity
    look.pitch += event.deltaY * sensitivity
    
    // Clamp pitch between -90 and 90
    look.pitch = min(max(-90, look.pitch), 90)
    // Wrap yaw to between 0 and 360
    let remainder = look.yaw.truncatingRemainder(dividingBy: 360)
    look.yaw = remainder < 0 ? 360 + remainder : remainder
  }
  
  /// Updates the player's velocity with an input event.
  public mutating func updateInputs(with event: InputEvent) {
    switch event.type {
      case .press:
        currentInputs.insert(event.input)
      case .release:
        currentInputs.remove(event.input)
    }
  }
  
  /// Updates the player's velocity.
  public mutating func updateVelocity() {
    // update velocity relative to yaw
    velocity = [0, 0, 0]
    if currentInputs.contains(.forward) {
      velocity.z = PhysicsEngine.playerSpeed
    } else if currentInputs.contains(.backward) {
      velocity.z = -PhysicsEngine.playerSpeed
    }

    if currentInputs.contains(.left) {
      velocity.x = PhysicsEngine.playerSpeed
    } else if currentInputs.contains(.right) {
      velocity.x = -PhysicsEngine.playerSpeed
    }

    if currentInputs.contains(.jump) {
      velocity.y = PhysicsEngine.playerSpeed
    } else if currentInputs.contains(.shift) {
      velocity.y = -PhysicsEngine.playerSpeed
    }

    if currentInputs.contains(.sprint) {
      velocity *= 2
    }

    // adjust to real velocity (using yaw)
    let yawRadians = Double(look.yaw * .pi / 180)
    var xz = SIMD2<Double>(velocity.x, velocity.z)
    // swiftlint:disable shorthand_operator
    xz = xz * MatrixUtil.rotationMatrix2dDouble(yawRadians)
    // swiftlint:enable shorthand_operator
    velocity.x = xz.x
    velocity.z = xz.y // z is the 2nd component of xz (aka y)
  }
}
