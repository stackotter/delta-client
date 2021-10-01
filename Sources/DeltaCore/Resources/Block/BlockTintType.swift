import Foundation

/// The type of tint color a block has.
extension Block {
  public enum TintType: String, Codable {
    case waterTint = "minecraft:water_tint"
    case foliageTint = "minecraft:foliage_tint"
    case grassTint = "minecraft:grass_tint"
    case sugarCaneTint = "minecraft:sugar_cane_tint"
    case lilyPadTint = "minecraft:lily_pad_tint"
    case shearingDoublePlantTint = "minecraft:shearing_double_plant_tint"
  }
}
