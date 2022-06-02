import Foundation

/// Information about a biome.
///
/// This only contains data that cannot be changed by resourcepacks. See ``BiomeColors`` if you
/// are looking for foliage and grass colors.
public struct Biome: Codable {
  /// The biome's unique id.
  public var id: Int
  /// The identifier used to refer to the biome in a user friendly way.
  public var identifier: Identifier
  
  /// Don't know what this does yet.
  public var depth: Float = 0
  /// Don't know what this does yet.
  public var scale: Float = 0
  /// The biome's default temperature value. Used to find biome colors.
  public var temperature: Float = 0
  /// The biome's default rainfall value. Used to find biome colors.
  public var rainfall: Float = 0
  
  /// The color of render distance fog.
  public var fogColor = RGBColor.white
  /// The color of the sky.
  public var skyColor = RGBColor.white
  /// The color of the water block.
  public var waterColor = RGBColor.white
  /// The color of the haze seen underwater.
  public var waterFogColor = RGBColor.white
  
  /// The group the biome is part of.
  public var category = Category.none
  /// The type of precipitation that occurs in this biome.
  public var precipitationType = PrecipitationType.none
  
  // MARK: Init
  
  /// Creates a biome with the given parameters.
  /// - Parameters:
  ///   - id: The biome's unique id.
  ///   - identifier: The identifier used to refer to the biome in a user friendly way.
  ///   - depth: See ``depth``. Defaults to 0.
  ///   - scale: See ``scale``. Defaults to 0.
  ///   - temperature: See ``temperature``. Defaults to 0.
  ///   - rainfall: See ``rainfall``. Defaults to 0.
  ///   - fogColor: See ``fogColor``. Defaults to ``RGBColor/white``.
  ///   - skyColor: See ``skyColor``. Defaults to ``RGBColor/white``.
  ///   - waterColor: See ``waterColor``. Defaults to ``RGBColor/white``.
  ///   - waterFogColor: See ``waterFogColor``. Defaults to ``RGBColor/white``.
  ///   - category: See ``category``. Defaults to ``Category/none``.
  ///   - precipitationType: See ``precipitationType``. Defaults to ``PrecipitationType/none``.
  public init(
    id: Int,
    identifier: Identifier,
    depth: Float = 0,
    scale: Float = 0,
    temperature: Float = 0,
    rainfall: Float = 0,
    fogColor: RGBColor = RGBColor.white,
    skyColor: RGBColor = RGBColor.white,
    waterColor: RGBColor = RGBColor.white,
    waterFogColor: RGBColor = RGBColor.white,
    category: Biome.Category = Category.none,
    precipitationType: Biome.PrecipitationType = PrecipitationType.none
  ) {
    self.id = id
    self.identifier = identifier
    self.depth = depth
    self.scale = scale
    self.temperature = temperature
    self.rainfall = rainfall
    self.fogColor = fogColor
    self.skyColor = skyColor
    self.waterColor = waterColor
    self.waterFogColor = waterFogColor
    self.category = category
    self.precipitationType = precipitationType
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
