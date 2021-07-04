//
//  PixlyzerBlock.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

public struct PixlyzerBlock: Codable {
  public var id: Int
  public var explosionResistance: Double
  public var item: Int
  public var friction: Double?
  public var velocityMultiplier: Double?
  public var jumpVelocityMultiplier: Double?
  public var defaultState: Int
  public var hasDynamicShape: Bool?
  public var `class`: String
  public var stillFluid: Int?
  public var flowFluid: Int?
  public var fluid: Int?
  public var offsetType: String?
  public var lavaParticles: Bool?
  public var flameParticle: Bool?
  public var tint: Identifier?
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
    case `class`
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
  
  /// A dictionary mapping block state id to an array of block model variants.
  var blockModels: [Int: [PixlyzerBlockModel]] {
    return states.mapValues { $0.renderDescriptor.variants }
  }
  
  /// This block in a neater format with default values instead of optionals where available.
  public func getBlock() -> Block {
    return Block(
      id: id,
      explosionResistance: explosionResistance,
      item: item,
      friction: friction ?? 0.6,
      velocityMultiplier: 1.0,
      jumpVelocityMultiplier: 1.0,
      defaultState: defaultState,
      hasDynamicShape: false,
      class: self.class,
      stillFluid: stillFluid,
      flowFluid: flowFluid,
      fluid: fluid,
      offsetType: offsetType,
      lavaParticles: lavaParticles ?? false,
      flameParticle: flameParticle ?? false,
      tint: tint,
      tintColor: tintColor,
      states: [Int](states.keys))
  }
  
  /// Returns an array of all states of this block in a neater format and the correct order.
  public func getBlockStates() -> [BlockState] {
    var blockStates: [BlockState] = []
    for (id, state) in states {
      let blockState = BlockState(
        id: id,
        blockId: self.id,
        luminance: state.luminance ?? 0,
        isRandomlyTicking: state.isRandomlyTicking ?? false,
        hasSidedTransparency: state.hasSidedTransparency ?? false,
        soundVolume: state.soundVolume,
        soundPitch: state.soundPitch,
        breakSound: state.breakSound,
        stepSound: state.stepSound,
        placeSound: state.placeSound,
        hitSound: state.hitSound,
        fallSound: state.fallSound,
        requiresTool: state.requiresTool,
        hardness: state.hardness,
        isOpaque: state.isOpaque ?? true,
        material: state.material,
        tintColor: state.tintColor ?? -1,
        collisionShape: state.collisionShape,
        outlineShape: state.outlineShape,
        solidRender: state.solidRender,
        translucent: state.translucent,
        lightBlock: state.lightBlock,
        largeCollisionShape: state.largeCollisionShape,
        isCollisionShapeFullBlock: state.isCollisionShapeFullBlock,
        occlusionShape: state.occlusionShape,
        occlusionShapes: state.occlusionShapes,
        isSturdy: state.isSturdy)
      blockStates.append(blockState)
    }
    return blockStates
  }
}
