/// The state of a fluid 'block'.
public struct FluidState: Codable {
  /// The type of fluid.
  public var fluidId: Int
  /// The height of the fluid from 0 to 7 (lowest to highest).
  public var height: Int
  /// Is the fluid part of a waterlogged block.
  public var isWaterlogged: Bool

  /// The fluid this fluid state is for.
  public var fluid: Fluid {
    return RegistryStore.shared.fluidRegistry.fluid(withId: fluidId)
  }

  public init(fluidId: Int, height: Int, isWaterlogged: Bool) {
    self.fluidId = fluidId
    self.height = height
    self.isWaterlogged = isWaterlogged
  }
}
