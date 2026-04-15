import FirebladeECS

public class EnderDragonParts: Component {
  public var head = Part(
    .head,
    size: Vec2d(1, 1),
    entityIdOffset: 1,
    relativePosition: Vec3d(-0.5, 0, 1)
  )
  public var neck = Part(
    .neck,
    size: Vec2d(3, 3),
    entityIdOffset: 2,
    relativePosition: Vec3d(-1.5, -1, -2)
  )
  public var body = Part(
    .body,
    size: Vec2d(5, 3),
    entityIdOffset: 3,
    relativePosition: Vec3d(-2.5, -1, -4)
  )
  // TODO: Verify the entity id offsets of these
  public var upperTail = Part(
    .tail,
    size: Vec2d(2, 2),
    entityIdOffset: 4,
    relativePosition: Vec3d(-1, -0.5, -5)
  )
  public var midTail = Part(
    .tail,
    size: Vec2d(2, 2),
    entityIdOffset: 5,
    relativePosition: Vec3d(-1, -0.5, -6)
  )
  public var lowerTail = Part(
    .tail,
    size: Vec2d(2, 2),
    entityIdOffset: 6,
    relativePosition: Vec3d(-1, -0.5, -7)
  )
  public var leftWing = Part(
    .wing,
    size: Vec2d(4, 2),
    entityIdOffset: 7,
    relativePosition: Vec3d(2, 0, -4)
  )
  public var rightWing = Part(
    .wing,
    size: Vec2d(4, 2),
    entityIdOffset: 8,
    relativePosition: Vec3d(-6, 0, -4)
  )

  /// All parts.
  public var parts: [Part] {
    [head, neck, body, upperTail, midTail, lowerTail, leftWing, rightWing]
  }

  public init() {}

  public struct Part {
    /// Group that this part is a member of (e.g. tail).
    public var group: Group
    /// The size of the part's hitbox as a width (x and z) and a height (y).
    public var size: Vec2d
    /// The offset of this part's entity id from the parent entity's id.
    public var entityIdOffset: Int
    /// Position relative to parent entity.
    public var relativePosition: Vec3d

    public enum Group {
      case head
      case neck
      case body
      case tail
      case wing
    }

    public init(
      _ group: Group,
      size: Vec2d,
      entityIdOffset: Int,
      relativePosition: Vec3d
    ) {
      self.group = group
      self.size = size
      self.entityIdOffset = entityIdOffset
      self.relativePosition = relativePosition
    }

    public func aabb(withParentPosition parentPosition: Vec3d) -> AxisAlignedBoundingBox {
      AxisAlignedBoundingBox(
        position: parentPosition + relativePosition,
        size: Vec3d(size.x, size.y, size.x)
      )
    }
  }
}
