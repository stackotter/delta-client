import Foundation

/// Block data from pixlyzer.
public struct PixlyzerBlock: Decodable {
  public var id: Int
  public var explosionResistance: Double
  public var item: Int
  public var friction: Double?
  public var velocityMultiplier: Double?
  public var jumpVelocityMultiplier: Double?
  public var defaultState: Int
  public var hasDynamicShape: Bool?
  public var className: String
  public var stillFluid: Int?
  public var flowFluid: Int?
  public var fluid: Int?
  public var offsetType: String?
  public var maxModelOffset: Float?
  public var lavaParticles: Bool?
  public var flameParticle: Int?
  public var tint: Block.TintType?
  public var tintColor: Int?
  public var states: [Int: PixlyzerBlockState]
  
  enum CodingKeys: String, CodingKey {
    case id
    case explosionResistance = "explosion_resistance"
    case item
    case friction
    case velocityMultiplier = "velocity_multiplier"
    case jumpVelocityMultiplier = "jump_velocity_multiplier"
    case defaultState = "default_state"
    case hasDynamicShape = "has_dynamic_shape"
    case className = "class"
    case stillFluid = "still_fluid"
    case flowFluid = "flow_fluid"
    case fluid
    case offsetType = "offset_type"
    case lavaParticles = "lava_particles"
    case flameParticle = "flame_particle"
    case tint
    case tintColor = "tint_color"
    case states
  }
  
  /// A dictionary mapping block state id to an array of block model variant model descriptors.
  var blockModelDescriptors: [Int: [[PixlyzerBlockModelDescriptor]]] {
    return states.mapValues { state in
      state.blockModelVariantDescriptors
    }
  }
}
