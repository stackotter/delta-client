import Foundation
import simd

public struct PixlyzerBiome: Codable {
  var id: Int
  var depth: Float
  var scale: Float
  var waterColor: Int
  var waterFogColor: Int
  var category: Int
  var precipitation: Float
  var temperature: Float
  var downfall: Float
  var fogColor: Int
  var skyColor: Int
}
