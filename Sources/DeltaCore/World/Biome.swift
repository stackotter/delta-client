import Foundation

public struct Biome {
  var identifier: Identifier
  var depth: Float
  var scale: Float
  var waterColor: Color
  var waterFogColor: Color
  var category: Int
  var precipitation: Float
  var temperatute: Float
  var downfall: Float
  var fogColor: Color
  var skyColor: Color
  
  // TODO: use to pattern instead of from pattern
  public init(from pixlyzerBiome: PixlyzerBiome, identifier: Identifier) {
    self.identifier = identifier
    self.depth = pixlyzerBiome.depth
    self.scale = pixlyzerBiome.scale
    self.waterColor = Color(hexCode: pixlyzerBiome.waterColor)
    self.waterFogColor = Color(hexCode: pixlyzerBiome.waterFogColor)
    self.category = pixlyzerBiome.category
    self.precipitation = pixlyzerBiome.precipitation
    self.temperatute = pixlyzerBiome.temperature
    self.downfall = pixlyzerBiome.downfall
    self.fogColor = Color(hexCode: pixlyzerBiome.fogColor)
    self.skyColor = Color(hexCode: pixlyzerBiome.skyColor)
  }
}
