import Foundation

/// Information about a fluid.
public struct Fluid {
  /// The fluids identifier in vanilla.
  public var identifier: Identifier
  /// The fluid's id.
  public var id: Int
  /// The type of fluid. This dictates its properties such as flow speed, spread radius and texture.
  public var type: FluidType
  
  /// Convert a pixlyzer fluid to this nicer format.
  /// - Parameters:
  ///   - pixlyzerFluid: The pixlyzer fluid to convert.
  ///   - identifier: The fluid's identifier.
  public init(from pixlyzerFluid: PixlyzerFluid, identifier: Identifier) {
    self.identifier = identifier
    id = pixlyzerFluid.id
    type = pixlyzerFluid.class
  }
}
