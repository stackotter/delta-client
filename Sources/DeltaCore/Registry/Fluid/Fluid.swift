import Foundation

/// Information about a fluid.
public struct Fluid {
  /// The fluids identifier in vanilla.
  public var identifier: Identifier
  /// The fluid's id.
  public var id: Int
  /// The type of fluid. This dictates its properties such as flow speed, spread radius.
  public var type: FluidType
  /// Texture to render fluid with.
  public var texture: Identifier
  
  /// Convert a pixlyzer fluid to this nicer format.
  /// - Parameters:
  ///   - pixlyzerFluid: The pixlyzer fluid to convert.
  ///   - identifier: The fluid's identifier.
  public init(from pixlyzerFluid: PixlyzerFluid, identifier: Identifier) {
    self.identifier = identifier
    id = pixlyzerFluid.id
    type = pixlyzerFluid.class
    
    switch type {
      case .empty:
        texture = Identifier(name: "empty_fluid")
      case .flowingWater:
        texture = Identifier(name: "block/water_flow")
      case .stillWater:
        texture = Identifier(name: "block/water_still")
      case .flowingLava:
        texture = Identifier(name: "block/lava_flow")
      case .stillLava:
        texture = Identifier(name: "block/lava_still")
    }
  }
}
