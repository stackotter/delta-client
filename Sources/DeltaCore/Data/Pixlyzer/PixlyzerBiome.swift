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
