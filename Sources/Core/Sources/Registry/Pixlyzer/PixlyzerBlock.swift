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
  public var offsetType: Block.Offset?
  public var tint: Block.ComputedTintType?
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
    case offsetType = "offset_type"
    case tint
    case states
  }
}

extension Block {
  // swiftlint:disable function_body_length
  public init(
    _ pixlyzerBlock: PixlyzerBlock,
    _ pixlyzerState: PixlyzerBlockState,
    shapes: [[AxisAlignedBoundingBox]],
    stateId: Int,
    fluid: Fluid?,
    isWaterlogged: Bool,
    identifier: Identifier
  ) {
    let fluidState: FluidState?
    if let fluid = fluid {
      let height = 7 - (pixlyzerState.properties?.level ?? 0)
      fluidState = FluidState(
        fluidId: fluid.id,
        height: isWaterlogged ? 7 : height,
        isWaterlogged: isWaterlogged)
    } else {
      fluidState = nil
    }

    let tint: Tint?
    if let computedTint = pixlyzerBlock.tint {
      tint = .computed(computedTint)
    } else if let hardcodedColor = pixlyzerState.tintColor {
      tint = .hardcoded(RGBColor(hexCode: hardcodedColor))
    } else {
      tint = nil
    }

    let material = Block.PhysicalMaterial(
      explosionResistance: pixlyzerBlock.explosionResistance,
      slipperiness: pixlyzerBlock.friction ?? 0.6,
      velocityMultiplier: pixlyzerBlock.velocityMultiplier ?? 1,
      jumpVelocityMultiplier: pixlyzerBlock.jumpVelocityMultiplier ?? 1,
      requiresTool: pixlyzerState.requiresTool,
      hardness: pixlyzerState.hardness)

    let lightMaterial = Block.LightMaterial(
      isTranslucent: pixlyzerState.translucent ?? false,
      opacity: pixlyzerState.lightBlock ?? 1,
      luminance: pixlyzerState.luminance ?? 0,
      isConditionallyTransparent: pixlyzerState.hasSidedTransparency ?? false)

    let soundMaterial = Block.SoundMaterial(
      volume: pixlyzerState.soundVolume,
      pitch: pixlyzerState.soundPitch,
      breakSound: pixlyzerState.breakSound,
      stepSound: pixlyzerState.stepSound,
      placeSound: pixlyzerState.placeSound,
      hitSound: pixlyzerState.hitSound,
      fallSound: pixlyzerState.fallSound)

    var collisionShape = CompoundBoundingBox()
    if let collisionShapeId = pixlyzerState.collisionShape {
      collisionShape.addAABBs(shapes[collisionShapeId])
    }

    var outlineShape = CompoundBoundingBox()
    if let outlineShapeId = pixlyzerState.outlineShape {
      outlineShape.addAABBs(shapes[outlineShapeId])
    }

    let shape = Block.Shape(
      isDynamic: pixlyzerBlock.hasDynamicShape ?? false,
      isLarge: pixlyzerState.largeCollisionShape ?? false,
      collisionShape: collisionShape,
      outlineShape: outlineShape,
      occlusionShape: pixlyzerState.occlusionShape?.items,
      isSturdy: pixlyzerState.isSturdy?.items)

    self.init(
      id: stateId,
      vanillaParentBlockId: pixlyzerBlock.id,
      identifier: identifier,
      className: pixlyzerBlock.className,
      fluidState: fluidState,
      tint: tint,
      offset: pixlyzerBlock.offsetType,
      material: material,
      lightMaterial: lightMaterial,
      soundMaterial: soundMaterial,
      shape: shape)
  }
  // swiftlint:enable function_body_length
}
