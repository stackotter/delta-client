import FirebladeECS

/// A component storing attributes specific to the client's player.
public class PlayerAttributes: Component {
  /// The player's spawn position.
  public var spawnPosition = Position(x: 0, y: 0, z: 0)
  /// The player's maximum flying speed (set by server).
  public var flyingSpeed: Float = 0
  /// The player's current fov modifier.
  public var fovModifier: Float = 0
  /// Whether the player is invulnerable to damage or not. In creative mode this is `true`.
  public var isInvulnerable = false
  /// Whether the player is allowed to fly or not.
  public var canFly = false
  /// Whether the player can instantly break blocks.
  public var canInstantBreak = false
  /// Whether the player is in hardcore mode or not. Affects respawn screen and rendering of hearts.
  public var isHardcore = false
  /// The player's previous gamemode. Likely used in vanilla by the F3+F4 gamemode switcher.
  public var previousGamemode: Gamemode? = nil
  
  /// Creates the player's attributes.
  /// - Parameters:
  ///   - spawnPosition: Defaults to (0, 0, 0).
  ///   - flyingSpeed: Defaults to 0.
  ///   - fovModifier: Defaults to 0.
  ///   - isInvulnerable: Defaults to false.
  ///   - canFly: Defaults to false.
  ///   - canInstantBreak: Defaults to false.
  ///   - isHardcore: Defaults to false.
  ///   - previousGamemode: Defaults to ``Gamemode/survival``.
  public init(
    spawnPosition: Position = Position(x: 0, y: 0, z: 0),
    flyingSpeed: Float = 0,
    fovModifier: Float = 0,
    isInvulnerable: Bool = false,
    canFly: Bool = false,
    canInstantBreak: Bool = false,
    isHardcore: Bool = false,
    previousGamemode: Gamemode = Gamemode.survival
  ) {
    self.spawnPosition = spawnPosition
    self.flyingSpeed = flyingSpeed
    self.fovModifier = fovModifier
    self.isInvulnerable = isInvulnerable
    self.canFly = canFly
    self.canInstantBreak = canInstantBreak
    self.isHardcore = isHardcore
    self.previousGamemode = previousGamemode
  }
}
