extension Block {
  /// Information about the shape of a block. Used for both occlusion (in lighting) and collisions.
  public struct Shape: Codable {
    /// Used for missing blocks.
    public static var `default` = Shape(
      isDynamic: false,
      isLarge: false,
      collisionShape: CompoundBoundingBox(),
      outlineShape: CompoundBoundingBox(),
      occlusionShapeIds: nil,
      isSturdy: nil
    )

    /// Whether the block's shape can change dynamically (with an animation). E.g. pistons extending.
    public var isDynamic: Bool
    /// Whether the collision shape is bigger than a block.
    public var isLarge: Bool
    /// The shape to use as the collision shape for this block.
    public var collisionShape: CompoundBoundingBox
    /// The shape that represent the outline to render for this block.
    public var outlineShape: CompoundBoundingBox

    /// The id of the shapes to use for occlusion. I don't really know how this works or why there are multiple.
    public var occlusionShapeIds: [Int]?
    /// Don't really know yet what this is.
    public var isSturdy: [Bool]?

    /// Create a new block shape with some properties.
    public init(
      isDynamic: Bool,
      isLarge: Bool,
      collisionShape: CompoundBoundingBox,
      outlineShape: CompoundBoundingBox,
      occlusionShapeIds: [Int]? = nil,
      isSturdy: [Bool]? = nil
    ) {
      self.isDynamic = isDynamic
      self.isLarge = isLarge
      self.collisionShape = collisionShape
      self.outlineShape = outlineShape
      self.occlusionShapeIds = occlusionShapeIds
      self.isSturdy = isSturdy
    }
  }
}
