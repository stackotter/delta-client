/// A fluid. Vanilla only has water and lava.
public final class Fluid: Codable {
  /// The id of the fluid in the fluid registry.
  public var id: Int
  /// The fluids identifier in vanilla.
  public var identifier: Identifier
  /// The texture to use when this fluid is flowing.
  public var flowingTexture: Identifier
  /// The texture to use when this fluid is still.
  public var stillTexture: Identifier
  /// The id of the particle to use when this fluid is seeping through the ground.
  public var dripParticleType: Int?
  
  public init(
    id: Int,
    identifier: Identifier,
    flowingTexture: Identifier,
    stillTexture: Identifier,
    dripParticleType: Int?
  ) {
    self.id = id
    self.identifier = identifier
    self.flowingTexture = flowingTexture
    self.stillTexture = stillTexture
    self.dripParticleType = dripParticleType
  }
}
