import Foundation
import FirebladeMath

/// An axis aligned bounding box used for efficient collisions and visibility checks.
public struct AxisAlignedBoundingBox: Codable {
  // MARK: Public properties

  /// The position of the minimum vertex of the bounding box.
  public var position: Vec3d
  /// The size of the bounding box.
  public var size: Vec3d

  /// The minimum vertex of the bounding box.
  public var minimum: Vec3d {
    position
  }

  /// The maximum vertex of the bounding box.
  public var maximum: Vec3d {
    position + size
  }

  /// All of the block positions that this AABB overlaps with.
  public var blockPositions: [BlockPosition] {
    let minX = Int(minimum.x.rounded(.down))
    let maxX = Int(maximum.x.rounded(.down))
    let minY = Int(minimum.y.rounded(.down))
    let maxY = Int(maximum.y.rounded(.down))
    let minZ = Int(minimum.z.rounded(.down))
    let maxZ = Int(maximum.z.rounded(.down))

    var positions: [BlockPosition] = []
    positions.reserveCapacity((maxX - minX + 1) * (maxY - minY + 1) * (maxZ - minZ + 1))

    for x in minX...maxX {
      for y in minY...maxY {
        for z in minZ...maxZ {
          positions.append(BlockPosition(x: x, y: y, z: z))
        }
      }
    }

    return positions
  }

  // MARK: Init

  /// Create a new axis aligned bounding box at a position with a given size.
  /// - Parameters:
  ///   - position: The position of the bounding box.
  ///   - size: The size of the bounding box. Must be positive. The absolute value is taken just in case.
  public init(position: Vec3d, size: Vec3d) {
    self.position = position
    self.size = MathUtil.abs(size)
  }

  /// Create a new axis aligned bounding box with given minimum and maximum vertices.
  /// - Parameters:
  ///   - minimum: The minimum vertex.
  ///   - maximum: The maximum vertex.
  public init(minimum: Vec3d, maximum: Vec3d) {
    position = minimum
    size = MathUtil.abs(maximum - minimum)
  }

  // MARK: Public methods

  /// Get an array containing all 8 of this bounding box's vertices.
  /// - Returns: This bounding box's vertices.
  public func getVertices() -> [Vec3d] {
    let minimum = minimum
    let maximum = maximum

    let bfl = minimum
    let bfr = Vec3d(maximum.x, minimum.y, minimum.z)
    let tfl = Vec3d(minimum.x, maximum.y, minimum.z)
    let tfr = Vec3d(maximum.x, maximum.y, minimum.z)

    let bbl = Vec3d(minimum.x, minimum.y, maximum.z)
    let bbr = Vec3d(maximum.x, minimum.y, maximum.z)
    let tbl = Vec3d(minimum.x, maximum.y, maximum.z)
    let tbr = maximum

    return [bfl, bfr, tfl, tfr, bbl, bbr, tbl, tbr]
  }

  /// Get an array containing all 8 of this bounding box's vertices in homogenous form.
  /// - Returns: This bounding box's vertices in homogenous form.
  public func getHomogenousVertices() -> [Vec4d] {
    let minimum = minimum
    let maximum = maximum

    let bfl = Vec4d(minimum, 1)
    let bfr = Vec4d(maximum.x, minimum.y, minimum.z, 1)
    let tfl = Vec4d(minimum.x, maximum.y, minimum.z, 1)
    let tfr = Vec4d(maximum.x, maximum.y, minimum.z, 1)

    let bbl = Vec4d(minimum.x, minimum.y, maximum.z, 1)
    let bbr = Vec4d(maximum.x, minimum.y, maximum.z, 1)
    let tbl = Vec4d(minimum.x, maximum.y, maximum.z, 1)
    let tbr = Vec4d(maximum, 1)

    return [bfl, bfr, tfl, tfr, bbl, bbr, tbl, tbr]
  }

  /// Moves the bounding box by the given amount.
  public func offset(by vector: Vec3d) -> AxisAlignedBoundingBox {
    var aabb = self
    aabb.position += vector
    return aabb
  }

  /// Moves the bounding box by the given amount along a given axis.
  /// - Parameters:
  ///   - amount: The amount to move the bounding box by.
  ///   - axis: The axis to move the bounding box along.
  /// - Returns: The offset bounding box.
  public func offset(by amount: Double, along axis: Axis) -> AxisAlignedBoundingBox {
    return offset(by: axis.positiveDirection.doubleVector * amount)
  }

  /// Extends the bounding box by the given amount in the given direction.
  public func extend(_ direction: Direction, amount: Double) -> AxisAlignedBoundingBox {
    var aabb = self
    aabb.size += MathUtil.abs(direction.doubleVector * amount)
    if !direction.isPositive {
      aabb.position += direction.doubleVector * amount
    }
    return aabb
  }

  /// Grows by the given amount in each direction.
  /// - Parameter amount: The amount to grow by.
  /// - Returns: The new bounding box.
  public func grow(by amount: Double) -> AxisAlignedBoundingBox {
    return grow(by: Vec3d(repeating: amount))
  }

  /// Grows by the given amount in each direction.
  /// - Parameter vector: The amount to grow by on each axis. The bounding box will grow by the given amount in both directions along the axis.
  /// - Returns: The new bounding box.
  public func grow(by vector: Vec3d) -> AxisAlignedBoundingBox {
    var aabb = self
    aabb.position -= vector
    aabb.size += 2 * vector
    return aabb
  }

  /// Shrinks by the given amount in each direction.
  /// - Parameter amount: The amount to shrink by.
  /// - Returns: The new bounding box.
  public func shrink(by amount: Double) -> AxisAlignedBoundingBox {
    return grow(by: -amount)
  }

  /// Shrinks by the given amount in each direction.
  /// - Parameter vector: The amount to shrink by on each axis. The bounding box will shrink by the given amount in both directions along the axis.
  /// - Returns: The new bounding box.
  public func shrink(by vector: Vec3d) -> AxisAlignedBoundingBox {
    return grow(by: -vector)
  }

  /// Checks whether the AABB overlaps with another given AABB.
  /// - Parameter other: The AABB to check for intersection with.
  /// - Returns: `true` if the AABBs intersect.
  public func intersects(with other: AxisAlignedBoundingBox) -> Bool {
    let minimum = minimum
    let maximum = maximum

    let otherMinimum = other.minimum
    let otherMaximum = other.maximum

    return (
      minimum.x <= otherMaximum.x && maximum.x >= otherMinimum.x &&
      minimum.y <= otherMaximum.y && maximum.y >= otherMinimum.y &&
      minimum.z <= otherMaximum.z && maximum.z >= otherMinimum.z)
  }

  /// Checks whether the AABB intersects with the given AABB.
  /// - Parameter ray: The ray to check for intersection with.
  /// - Returns: `true` if the ray intersects with the AABB.
  public func intersects(with ray: Ray) -> Bool {
    return intersectionDistanceAndFace(with: ray) != nil
  }

  /// Checks whether the AABB overlaps with a given ray.
  /// - Parameter ray: The ray to check for intersection with.
  /// - Returns: `true` if the ray intersects the AABB.
  public func intersectionDistanceAndFace(with ray: Ray) -> (distance: Float, face: Direction)? {
    // Algorithm explanation: https://tavianator.com/2011/ray_box.html
    // As outlined in that post, this algorithm can be optimized if required

    var entryAxis: Axis? = nil

    let inverseDirection = 1 / ray.direction
    let minimum = Vec3f(minimum)
    let maximum = Vec3f(maximum)

    let tx1 = (minimum.x - ray.origin.x) * inverseDirection.x
    let tx2 = (maximum.x - ray.origin.x) * inverseDirection.x

    var tmin = min(tx1, tx2)
    var tmax = max(tx1, tx2)

    if !tmin.isNaN {
      entryAxis = .x
    }

    var prevtmin = tmin
    let ty1 = (minimum.y - ray.origin.y) * inverseDirection.y
    let ty2 = (maximum.y - ray.origin.y) * inverseDirection.y

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    if tmin != prevtmin {
      entryAxis = .y
    }

    prevtmin = tmin
    let tz1 = (minimum.z - ray.origin.z) * inverseDirection.z
    let tz2 = (maximum.z - ray.origin.z) * inverseDirection.z

    tmin = max(tmin, min(tz1, tz2))
    tmax = min(tmax, max(tz1, tz2))

    if tmin != prevtmin {
      entryAxis = .z
    }

    guard let axis = entryAxis, tmax >= tmin else {
      return nil
    }

    // The entry face is opposite to the direction the player is looking along the entry axis
    let face: Direction
    if ray.direction.component(along: axis) > 0 {
      face = axis.negativeDirection
    } else {
      face = axis.positiveDirection
    }

    return (tmin, face)
  }
}
