import Foundation
import simd

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

extension Block {
  /// Returns the offset to apply to the given block at the given position when rendering.
  public func getModelOffset(at position: Position) -> simd_float3 {
    if let offsetType = offsetType {
      let seed = Self.getPositionRandom(Position(x: position.x, y: 0, z: position.z))
      return simd_float3(
        x: Float(seed & 15) / 30 - 0.25,
        y: offsetType == "xyz" ? Float((seed >> 4) & 15) / 75 - 0.2 : 0,
        z: Float((seed >> 8) & 15) / 30 - 0.25)
    } else {
      return simd_float3()
    }
  }
  
  /// Returns the seed to use for choosing block models. Identical behaviour to vanilla.
  public static func getPositionRandom(_ position: Position) -> Int64 {
    var seed = Int64(position.x &* 3129871) ^ (Int64(position.z) &* 116129781) ^ Int64(position.y);
    seed = (seed &* seed &* 42317861) &+ (seed &* 11);
    return seed >> 16;
  }
}
