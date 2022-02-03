import Foundation

extension Biome {
  /// The type of precipitation that occurs in a biome.
  public enum PrecipitationType: Int, Codable {
    case none
    case rain
    case snow
  }
}
