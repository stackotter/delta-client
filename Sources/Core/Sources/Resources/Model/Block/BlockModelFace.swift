import Foundation
import FirebladeMath

/// A descriptor for a block model element's face
public struct BlockModelFace: Equatable {
  /// The direction the face should face before transformations are applied.
  /// This won't always be the direction the face ends up facing.
  public var direction: Direction
  /// The actual direction the face will be facing after transformations are applied.
  public var actualDirection: Direction
  /// Face texture uv coordinates. One uv coordinate for each corner of the face.
  ///
  /// The order of these UVs should match the vertex ordering of each face defined by
  /// ``CubeGeometry``. The winding order of course differs per face.
  public var uvs: UVs
  /// The index of the texture to use in the texture palette.
  public var texture: Int
  /// The direction that a culling block must be in for this face not to be rendered.
  public var cullface: Direction?
  /// Whether the face should have a tint color applied or not.
  public var isTinted: Bool

  /// Basically tuple storage for a face-worth of UVs except that it can conform to ``Equatable``.
  /// See ``BlockModelFace/uvs`` for information about ordering.
  public struct UVs: Equatable {
    public var uv0: Vec2f
    public var uv1: Vec2f
    public var uv2: Vec2f
    public var uv3: Vec2f

    public init(_ uv0: Vec2f, _ uv1: Vec2f, _ uv2: Vec2f, _ uv3: Vec2f) {
      self.uv0 = uv0
      self.uv1 = uv1
      self.uv2 = uv2
      self.uv3 = uv3
    }

    public subscript(_ index: Int) -> Vec2f {
      get {
        precondition(index < 4 && index >= 0)
        return withUnsafePointer(to: self) { pointer in
          return pointer.withMemoryRebound(to: Vec2f.self, capacity: 4) { buffer in
            return buffer[index]
          }
        }
      }
    }
  }

  public init(
    direction: Direction,
    actualDirection: Direction,
    uvs: UVs,
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
