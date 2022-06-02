import Foundation
import simd

public struct PixlyzerBiome: Codable {
  public var id: Int
  public var depth: Float
  public var scale: Float
  public var waterColor: Int
  public var waterFogColor: Int
  public var category: Biome.Category
  public var precipitation: Biome.PrecipitationType
  public var temperature: Float
  public var downfall: Float
  public var fogColor: Int
  public var skyColor: Int
}

extension Biome {
  /// Convert a pixlyzer biome to this nicer format.
  /// - Parameters:
  ///   - pixlyzerBiome: The pixlyzer biome to convert.
  ///   - identifier: The biome's identifier.
  public init(from pixlyzerBiome: PixlyzerBiome, identifier: Identifier) {
    self = Biome(
      id: pixlyzerBiome.id,
      identifier: identifier,
      depth: pixlyzerBiome.depth,
      scale: pixlyzerBiome.scale,
      temperature: pixlyzerBiome.temperature,
      rainfall: pixlyzerBiome.downfall,
      fogColor: RGBColor(hexCode: pixlyzerBiome.fogColor),
      skyColor: RGBColor(hexCode: pixlyzerBiome.skyColor),
      waterColor: RGBColor(hexCode: pixlyzerBiome.waterColor),
      waterFogColor: RGBColor(hexCode: pixlyzerBiome.waterFogColor),
      category: pixlyzerBiome.category,
      precipitationType: pixlyzerBiome.precipitation)
  }
}
