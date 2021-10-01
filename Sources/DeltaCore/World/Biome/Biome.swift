import Foundation

/// Information about a biome.
///
/// This only contains data that cannot be changed by resourcepacks. See ``BiomeColors`` if you
/// are looking for foliage and grass colors.
public struct Biome {
  /// The biome's unique id.
  var id: Int
  /// The identifier used to refer to the biome in a user friendly way.
  var identifier: Identifier
  
  /// Don't know what this does yet.
  var depth: Float = 0
  /// Don't know what this does yet.
  var scale: Float = 0
  /// The biome's default temperature value. Used to find biome colors.
  var temperature: Float = 0
  /// The biome's default rainfall value. Used to find biome colors.
  var rainfall: Float = 0
  
  /// The color of render distance fog.
  var fogColor = RGBColor.white
  /// The color of the sky.
  var skyColor = RGBColor.white
  /// The color of the water block.
  var waterColor = RGBColor.white
  /// The color of the haze seen underwater.
  var waterFogColor = RGBColor.white
  
  /// The group the biome is part of.
  var category = Category.none
  /// The type of precipitation that occurs in this biome.
  var precipitationType = PrecipitationType.none
  
  // MARK: Init
  
  /// Creates a default biome.
  ///
  /// `depth`, `scale`, `temperature` and `rainfall` default to 0. `waterColor`, `waterFogColor`,
  /// `fogColor` and `skyColor` default to ``RGBColor.white``. `category` defaults to ``Category.none``
  /// and `precipitationType` defaults to ``PrecipitationType.none``.
  ///
  /// - Parameters:
  ///   - id: The biome's unique id.
  ///   - identifier: The identifier used to refer to the biome in a user friendly way.
  public init(id: Int, identifier: Identifier) {
    self.id = id
    self.identifier = identifier
  }
  
  /// Convert a pixlyzer biome to this nicer format.
  /// - Parameters:
  ///   - pixlyzerBiome: The pixlyzer biome to convert.
  ///   - identifier: The biome's identifier.
  public init(from pixlyzerBiome: PixlyzerBiome, identifier: Identifier) {
    self.id = pixlyzerBiome.id
    self.identifier = identifier
    self.depth = pixlyzerBiome.depth
    self.scale = pixlyzerBiome.scale
    self.waterColor = RGBColor(hexCode: pixlyzerBiome.waterColor)
    self.waterFogColor = RGBColor(hexCode: pixlyzerBiome.waterFogColor)
    self.category = pixlyzerBiome.category
    self.precipitationType = pixlyzerBiome.precipitation
    self.temperature = pixlyzerBiome.temperature
    self.rainfall = pixlyzerBiome.downfall
    self.fogColor = RGBColor(hexCode: pixlyzerBiome.fogColor)
    self.skyColor = RGBColor(hexCode: pixlyzerBiome.skyColor)
  }
  
  // MARK: Helper
  
  /// Check if the biome fits a criteria.
  /// - Parameter criteria: The criteria to check.
  /// - Returns: `true` if the biome fits the criteria.
  public func satisfies(_ criteria: Criteria) -> Bool {
    switch criteria {
      case .identifier(let identifier):
        return self.identifier == identifier
      case .category(let category):
        return self.category == category
    }
  }
}
