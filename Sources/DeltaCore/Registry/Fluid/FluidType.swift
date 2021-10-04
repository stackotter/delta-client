import Foundation

/// Type of fluid. Dictates its properties such as flow speed, spread radius and texture.
public enum FluidType: String, Codable {
  case empty = "EmptyFluid"
  case flowingWater = "WaterFluid$Flowing"
  case stillWater = "WaterFluid$Still"
  case flowingLava = "LavaFluid$Flowing"
  case stillLava = "LavaFluid$Still"
}
