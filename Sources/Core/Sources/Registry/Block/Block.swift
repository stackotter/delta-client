import Foundation
import FirebladeMath

/// Information about a specific block state.
public struct Block: Codable {
  /// The vanilla block state id of this block.
  public var id: Int
  /// The id of the overarching vanilla block that this state is part of. E.g. the different orientations of oak stairs all have the same parent id.
  public var vanillaParentBlockId: Int
  /// The identifier of this block.
  public var identifier: Identifier
  /// The name of the java class for this block (from yarn mappings).
  public var className: String
  /// The state of the fluid associated with this block.
  public var fluidState: FluidState?
  /// A tint to apply when rendering the block.
  public var tint: Tint?
  /// A type of random position offset to apply to the block.
  public var offset: Offset?
  /// Information about the physical properties of the block.
  public var material: PhysicalMaterial
  /// Information about the way the block interacts with light.
  public var lightMaterial: LightMaterial
  /// Information about the sound properties of the block.
  public var soundMaterial: SoundMaterial
  /// Information about the shape of the block.
  public var shape: Shape
  /// Properties of the block specific to each block state (e.g. direction of dispenser).
  public var stateProperties: StateProperties

  /// The id of the fluid in this block.
  public var fluidId: Int? {
    return fluidState?.fluidId
  }

  /// Whether the block is climable or not (e.g. a ladder or a vine).
  public var isClimbable: Bool {
    // TODO: Load block tags from Pixlyzer (or some other source if Pixlyzer doesn't have them)
    return ["LadderBlock", "VineBlock", "WeepingVinesBlock", "TwistingVinesPlantBlock"].contains(className)
  }

  /// Create a new block with the specified properties.
  public init(
    id: Int,
    vanillaParentBlockId: Int,
    identifier: Identifier,
    className: String,
    fluidState: FluidState? = nil,
    tint: Tint? = nil,
    offset: Offset? = nil,
    material: PhysicalMaterial,
    lightMaterial: LightMaterial,
    soundMaterial: SoundMaterial,
    shape: Shape,
    stateProperties: StateProperties
  ) {
    self.id = id
    self.vanillaParentBlockId = vanillaParentBlockId
    self.identifier = identifier
    self.className = className
    self.fluidState = fluidState
    self.tint = tint
    self.offset = offset
    self.material = material
    self.lightMaterial = lightMaterial
    self.soundMaterial = soundMaterial
    self.shape = shape
    self.stateProperties = stateProperties
  }

  /// Returns the offset to apply to the given block at the given position when rendering.
  public func getModelOffset(at position: BlockPosition) -> Vec3f {
    if let offset = offset {
      let seed = Self.getPositionRandom(BlockPosition(x: position.x, y: 0, z: position.z))
      let y: Float
      switch offset {
        case .xyz:
          y = Float((seed >> 4) & 15) / 75 - 0.2
        case .xz:
          y = 0
      }
      return Vec3f(
        x: Float(seed & 15) / 30 - 0.25,
        y: y,
        z: Float((seed >> 8) & 15) / 30 - 0.25)
    } else {
      return Vec3f()
    }
  }

  /// Returns the seed to use for choosing block models. Identical behaviour to vanilla.
  public static func getPositionRandom(_ position: BlockPosition) -> Int64 {
    var seed = Int64(position.x &* 3129871) ^ (Int64(position.z) &* 116129781) ^ Int64(position.y)
    seed = (seed &* seed &* 42317861) &+ (seed &* 11)
    return seed >> 16
  }

  /// Used when a block does not exist (e.g. when an invalid block id is received from the server).
  public static let missing = Block(
    id: -1,
    vanillaParentBlockId: -1,
    identifier: Identifier(name: "missing"),
    className: "MissingBlock",
    fluidState: nil,
    tint: nil,
    offset: nil,
    material: PhysicalMaterial.default,
    lightMaterial: LightMaterial.default,
    soundMaterial: SoundMaterial.default,
    shape: Shape.default,
    stateProperties: StateProperties.default
  )
}
