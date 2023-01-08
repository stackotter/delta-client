extension Block {
  /// The physical properties of a block.
  public struct PhysicalMaterial: Codable {
    /// How resistant the block is to breaking from explosions.
    public var explosionResistance: Double
    /// How much friction the block has. Most blocks have a value of 0.6
    public var slipperiness: Double
    /// Applied to entity velocity when on this block (e.g. soul sand has a multiplier lower than 1).
    public var velocityMultiplier: Double
    /// Applied to entity jump velocity when on this block (e.g. honey has a multiplier lower than 1).
    public var jumpVelocityMultiplier: Double
    /// Where the block requires a specific tool to break or not.
    public var requiresTool: Bool
    /// How hard the block is to break.
    public var hardness: Double

    public init(
      explosionResistance: Double,
      slipperiness: Double,
      velocityMultiplier: Double,
      jumpVelocityMultiplier: Double,
      requiresTool: Bool,
      hardness: Double
    ) {
      self.explosionResistance = explosionResistance
      self.slipperiness = slipperiness
      self.velocityMultiplier = velocityMultiplier
      self.jumpVelocityMultiplier = jumpVelocityMultiplier
      self.requiresTool = requiresTool
      self.hardness = hardness
    }

    /// Used for missing blocks.
    public static var `default` = PhysicalMaterial.init(
      explosionResistance: 0,
      slipperiness: 0.6,
      velocityMultiplier: 1,
      jumpVelocityMultiplier: 1,
      requiresTool: false,
      hardness: 0)
  }
}
