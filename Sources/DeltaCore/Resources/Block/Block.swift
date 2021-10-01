import Foundation
import simd

public struct Block {
  public var id: Int
  public var identifier: Identifier
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
  public var tintType: TintType?
  public var tintColor: RGBColor?
  public var states: [Int]
}

extension Block {
  /// Creates a block from pixlyzer data.
  public init(from pixlyzerBlock: PixlyzerBlock, identifier: Identifier) {
    self.identifier = identifier
    id = pixlyzerBlock.id
    explosionResistance = pixlyzerBlock.explosionResistance
    item = pixlyzerBlock.item
    friction = pixlyzerBlock.friction ?? 0.6
    velocityMultiplier = pixlyzerBlock.velocityMultiplier ?? 1.0
    jumpVelocityMultiplier = pixlyzerBlock.jumpVelocityMultiplier ?? 1.0
    defaultState = pixlyzerBlock.defaultState
    hasDynamicShape = pixlyzerBlock.hasDynamicShape ?? false
    className = pixlyzerBlock.className
    stillFluid = pixlyzerBlock.stillFluid
    flowFluid = pixlyzerBlock.flowFluid
    fluid = pixlyzerBlock.fluid
    offsetType = pixlyzerBlock.offsetType
    lavaParticles = pixlyzerBlock.lavaParticles ?? false
    flameParticle = pixlyzerBlock.flameParticle
    tintType = pixlyzerBlock.tint
    if let hexCode = pixlyzerBlock.tintColor {
      tintColor = RGBColor(hexCode: hexCode)
    }
    states = [Int](pixlyzerBlock.states.keys)
  }
  
  /// Used in place of missing blocks.
  public static let missing = Block(
    id: -1,
    identifier: Identifier(name: "missing"),
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
    tintType: nil,
    tintColor: nil,
    states: [])
}

extension Block {
  /// Returns the offset to apply to the given block at the given position when rendering.
  public func getModelOffset(at position: Position) -> SIMD3<Float> {
    if let offsetType = offsetType {
      let seed = Self.getPositionRandom(Position(x: position.x, y: 0, z: position.z))
      return SIMD3<Float>(
        x: Float(seed & 15) / 30 - 0.25,
        y: offsetType == "xyz" ? Float((seed >> 4) & 15) / 75 - 0.2 : 0,
        z: Float((seed >> 8) & 15) / 30 - 0.25)
    } else {
      return SIMD3<Float>()
    }
  }
  
  /// Returns the seed to use for choosing block models. Identical behaviour to vanilla.
  public static func getPositionRandom(_ position: Position) -> Int64 {
    var seed = Int64(position.x &* 3129871) ^ (Int64(position.z) &* 116129781) ^ Int64(position.y);
    seed = (seed &* seed &* 42317861) &+ (seed &* 11);
    return seed >> 16;
  }
}
