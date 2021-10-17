extension Block {
  /// Information about the shape of a block. Used for both occlusion (in lighting) and collisions.
  ///
  /// Don't exactly know what all of these mean yet. They're just from pixlyzer.
  public struct Shape: Codable{
    /// Whether the block's shape can change dynamically (with an animation). E.g. pistons extending.
    public var isDynamic: Bool
    /// Whether the collision shape is bigger than a block.
    public var isLarge: Bool
    /// The id of the shape to use for collisions.
    public var collisionShape: Int?
    /// The id of the shape to render as the block outline when targeted.
    public var outlineShape: Int?
    /// The id of the shapes to use for occlusion.
    public var occlusionShape: [Int]?
    /// Don't really know yet what this is.
    public var isSturdy: [Bool]?
    
    public init(
      isDynamic: Bool,
      isLarge: Bool,
      collisionShape: Int? = nil,
      outlineShape: Int? = nil,
      occlusionShape: [Int]? = nil,
      isSturdy: [Bool]? = nil
    ) {
      self.isDynamic = isDynamic
      self.isLarge = isLarge
      self.collisionShape = collisionShape
      self.outlineShape = outlineShape
      self.occlusionShape = occlusionShape
      self.isSturdy = isSturdy
    }
    
    /// Used for missing blocks.
    public static var `default` = Shape(
      isDynamic: false,
      isLarge: false,
      collisionShape: nil,
      outlineShape: nil,
      occlusionShape: nil,
      isSturdy: nil)
  }
}
