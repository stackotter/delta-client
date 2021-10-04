import Foundation

public struct BlockState {
  public var id: Int
  public var blockId: Int
  public var luminance: Int
  public var isRandomlyTicking: Bool
  public var isConditionallyTransparent: Bool
  public var soundVolume: Double
  public var soundPitch: Double
  public var breakSound: Int
  public var stepSound: Int
  public var placeSound: Int
  public var hitSound: Int
  public var fallSound: Int
  public var requiresTool: Bool
  public var hardness: Double
  public var isOpaque: Bool
  public var material: Identifier
  public var tintColor: Int
  public var collisionShape: Int?
  public var outlineShape: Int?
  public var solidRender: Bool?
  public var level: Int?
  public var translucent: Bool
  public var opacity: Int
  public var largeCollisionShape: Bool
  public var isCollisionShapeFullBlock: Bool
  public var occlusionShape: [Int]?
  public var isSturdy: [Bool]?
}

extension BlockState {
  public init(from pixlyzerBlockState: PixlyzerBlockState, withId id: Int, onBlockWithId blockId: Int) {
    self.id = id
    self.blockId = blockId
    luminance = pixlyzerBlockState.luminance ?? 0
    isRandomlyTicking = pixlyzerBlockState.isRandomlyTicking ?? false
    isConditionallyTransparent = pixlyzerBlockState.hasSidedTransparency ?? false
    soundVolume = pixlyzerBlockState.soundVolume
    soundPitch = pixlyzerBlockState.soundPitch
    breakSound = pixlyzerBlockState.breakSound
    stepSound = pixlyzerBlockState.stepSound
    placeSound = pixlyzerBlockState.placeSound
    hitSound = pixlyzerBlockState.hitSound
    fallSound = pixlyzerBlockState.fallSound
    requiresTool = pixlyzerBlockState.requiresTool
    hardness = pixlyzerBlockState.hardness
    isOpaque = pixlyzerBlockState.isOpaque ?? true
    material = pixlyzerBlockState.material
    tintColor = pixlyzerBlockState.tintColor ?? -1
    collisionShape = pixlyzerBlockState.collisionShape
    outlineShape = pixlyzerBlockState.outlineShape
    solidRender = pixlyzerBlockState.solidRender
    translucent = pixlyzerBlockState.translucent ?? false
    opacity = pixlyzerBlockState.lightBlock ?? 0
    largeCollisionShape = pixlyzerBlockState.largeCollisionShape ?? false
    isCollisionShapeFullBlock = pixlyzerBlockState.isCollisionShapeFullBlock ?? true
    level = pixlyzerBlockState.properties?.level
    
    if let occlusion = pixlyzerBlockState.occlusionShape {
      switch occlusion {
        case let .single(value):
          occlusionShape = [Int](repeating: value, count: 6)
        case let .multiple(array):
          occlusionShape = array
      }
    }
    
    if let sturdy = pixlyzerBlockState.isSturdy {
      switch sturdy {
        case let .single(value):
          isSturdy = [Bool](repeating: value, count: 6)
        case let .multiple(array):
          isSturdy = array
      }
    }
  }
  
  /// Used in place of missing block states.
  public static let missing = BlockState(
    id: -1,
    blockId: -1,
    luminance: 0,
    isRandomlyTicking: false,
    isConditionallyTransparent: false,
    soundVolume: 0,
    soundPitch: 0,
    breakSound: -1,
    stepSound: -1,
    placeSound: -1,
    hitSound: -1,
    fallSound: -1,
    requiresTool: false,
    hardness: 0,
    isOpaque: false,
    material: Identifier(name: "invalid"),
    tintColor: -1,
    collisionShape: nil,
    outlineShape: nil,
    solidRender: nil,
    level: nil,
    translucent: false,
    opacity: 1,
    largeCollisionShape: false,
    isCollisionShapeFullBlock: false,
    occlusionShape: nil,
    isSturdy: nil)
}
