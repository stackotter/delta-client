import Foundation

public struct Block {
  public var id: Int
  public var explosionResistance: Double
  public var item: Int
  public var friction: Double
  public var velocityMultiplier: Double
  public var jumpVelocityMultiplier: Double
  public var defaultState: Int
  public var hasDynamicShape: Bool
  public var className: String
  public var stillFluid: Int?
  public var flowFluid: Int?
  public var fluid: Int?
  public var offsetType: String?
  public var lavaParticles: Bool
  public var flameParticle: Int?
  public var tint: Identifier?
  public var tintColor: Int?
  public var states: [Int]
}

extension Block {
  /// Creates a block from pixlyzer data.
  public init(from pixlyzerBlock: PixlyzerBlock) {
    id = pixlyzerBlock.id
    explosionResistance = pixlyzerBlock.explosionResistance
    item = pixlyzerBlock.item
    friction = pixlyzerBlock.friction ?? 0.6
    velocityMultiplier = pixlyzerBlock.velocityMultiplier ?? 1.0
    jumpVelocityMultiplier = pixlyzerBlock.jumpVelocityMultiplier ?? 1.0
    defaultState = pixlyzerBlock.defaultState
    hasDynamicShape = pixlyzerBlock.hasDynamicShape ?? false
    className = pixlyzerBlock.class
    stillFluid = pixlyzerBlock.stillFluid
    flowFluid = pixlyzerBlock.flowFluid
    fluid = pixlyzerBlock.fluid
    offsetType = pixlyzerBlock.offsetType
    lavaParticles = pixlyzerBlock.lavaParticles ?? false
    flameParticle = pixlyzerBlock.flameParticle
    tint = pixlyzerBlock.tint
    tintColor = pixlyzerBlock.tintColor
    states = [Int](pixlyzerBlock.states.keys)
  }
  
  /// Used in place of missing blocks.
  public static let missing = Block(
    id: -1,
    explosionResistance: 0,
    item: -1,
    friction: 0,
    velocityMultiplier: 0,
    jumpVelocityMultiplier: 0,
    defaultState: -1,
    hasDynamicShape: false,
    className: "",
    stillFluid: nil,
    flowFluid: nil,
    fluid: nil,
    offsetType: nil,
    lavaParticles: false,
    flameParticle: nil,
    tint: nil,
    tintColor: nil,
    states: [])
}
