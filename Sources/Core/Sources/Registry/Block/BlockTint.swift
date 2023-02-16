extension Block {
  /// Information about what color to tint a block.
  public enum Tint: Codable {
    /// Apply a tint color computed from biome information and the type of block.
    case computed(ComputedTintType)
    /// Apply a harcoded tint color to every instance of the block.
    case hardcoded(RGBColor)
  }

  /// Types of tints that can be computed.
  public enum ComputedTintType: String, Codable {
    case waterTint = "minecraft:water_tint"
    case foliageTint = "minecraft:foliage_tint"
    case grassTint = "minecraft:grass_tint"
    case sugarCaneTint = "minecraft:sugar_cane_tint"
    case lilyPadTint = "minecraft:lily_pad_tint"
    case shearingDoublePlantTint = "minecraft:shearing_double_plant_tint"
  }
}
