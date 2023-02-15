import Foundation
import FirebladeMath

/// A descriptor for a block model element's face
public struct BlockModelFace: Equatable {
  /// The direction the face should face before transformations are applied.
  /// This won't always be the direction the face ends up facing.
  public var direction: Direction
  /// The actual direction the face will be facing after transformations are applied.
  public var actualDirection: Direction
  /// Face texture uv coordinates. One uv coordinate for each corner of the face (4 total).
  public var uvs: [Vec2f] // TODO: add a bit of info on which corner is which
  /// The index of the texture to use in the texture palette.
  public var texture: Int
  /// The direction that a culling block must be in for this face not to be rendered.
  public var cullface: Direction?
  /// Whether the face should have a tint color applied or not.
  public var isTinted: Bool

  public init(
    direction: Direction,
    actualDirection: Direction,
    uvs: [Vec2f],
    texture: Int,
    cullface: Direction? = nil,
    isTinted: Bool
  ) {
    self.direction = direction
    self.actualDirection = actualDirection
    self.uvs = uvs
    self.texture = texture
    self.cullface = cullface
    self.isTinted = isTinted
  }
}
