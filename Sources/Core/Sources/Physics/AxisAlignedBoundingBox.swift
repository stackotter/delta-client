import Foundation
import simd

/// An axis aligned bounding box used for efficient collisions and visibility checks.
public struct AxisAlignedBoundingBox: Codable {
  // MARK: Public properties

  /// The position of the minimum vertex of the bounding box.
  public var position: SIMD3<Double>
  /// The size of the bounding box.
  public var size: SIMD3<Double>

  /// The minimum vertex of the bounding box.
  public var minimum: SIMD3<Double> {
    position
  }

  /// The maximum vertex of the bounding box.
  public var maximum: SIMD3<Double> {
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
  public init(position: SIMD3<Double>, size: SIMD3<Double>) {
    self.position = position
    self.size = abs(size)
  }

  /// Create a new axis aligned bounding box with given minimum and maximum vertices.
  /// - Parameters:
  ///   - minimum: The minimum vertex.
  ///   - maximum: The maximum vertex.
  public init(minimum: SIMD3<Double>, maximum: SIMD3<Double>) {
    position = minimum
    size = abs(maximum - minimum)
  }

  // MARK: Public methods

  /// Get an array containing all 8 of this bounding box's vertices.
  /// - Returns: This bounding box's vertices.
  public func getVertices() -> [SIMD3<Double>] {
    let minimum = minimum
    let maximum = maximum

    let bfl = minimum
    let bfr = SIMD3(maximum.x, minimum.y, minimum.z)
    let tfl = SIMD3(minimum.x, maximum.y, minimum.z)
    let tfr = SIMD3(maximum.x, maximum.y, minimum.z)

    let bbl = SIMD3(minimum.x, minimum.y, maximum.z)
    let bbr = SIMD3(maximum.x, minimum.y, maximum.z)
    let tbl = SIMD3(minimum.x, maximum.y, maximum.z)
    let tbr = maximum

    return [bfl, bfr, tfl, tfr, bbl, bbr, tbl, tbr]
  }

  /// Get an array containing all 8 of this bounding box's vertices in homogenous form.
  /// - Returns: This bounding box's vertices in homogenous form.
  public func getHomogenousVertices() -> [SIMD4<Double>] {
    let minimum = minimum
    let maximum = maximum

    let bfl = SIMD4(minimum, 1)
    let bfr = SIMD4(maximum.x, minimum.y, minimum.z, 1)
    let tfl = SIMD4(minimum.x, maximum.y, minimum.z, 1)
    let tfr = SIMD4(maximum.x, maximum.y, minimum.z, 1)

    let bbl = SIMD4(minimum.x, minimum.y, maximum.z, 1)
    let bbr = SIMD4(maximum.x, minimum.y, maximum.z, 1)
    let tbl = SIMD4(minimum.x, maximum.y, maximum.z, 1)
    let tbr = SIMD4(maximum, 1)

    return [bfl, bfr, tfl, tfr, bbl, bbr, tbl, tbr]
  }

  /// Moves the bounding box by the given amount.
  public func offset(by vector: SIMD3<Double>) -> AxisAlignedBoundingBox {
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
    aabb.size += abs(direction.doubleVector * amount)
    if !direction.isPositive {
      aabb.position += direction.doubleVector * amount
    }
    return aabb
  }

  /// Grows by the given amount in each direction.
  /// - Parameter amount: The amount to grow by.
  /// - Returns: The new bounding box.
  public func grow(by amount: Double) -> AxisAlignedBoundingBox {
    return grow(by: SIMD3(repeating: amount))
  }

  /// Grows by the given amount in each direction.
  /// - Parameter vector: The amount to grow by on each axis. The bounding box will grow by the given amount in both directions along the axis.
  /// - Returns: The new bounding box.
  public func grow(by vector: SIMD3<Double>) -> AxisAlignedBoundingBox {
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
  public func shrink(by vector: SIMD3<Double>) -> AxisAlignedBoundingBox {
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
    return intersectionDistance(with: ray) != nil
  }

  /// Checks whether the AABB overlaps with a given ray.
  /// - Parameter ray: The ray to check for intersection with.
  /// - Returns: `true` if the ray intersects the AABB.
  public func intersectionDistance(with ray: Ray) -> Float? {
    // Algorithm explanation: https://tavianator.com/2011/ray_box.html
    // As outlined in that post, this algorithm can be optimized if required

    let inverseDirection = 1 / ray.direction
    let minimum = SIMD3<Float>(minimum)
    let maximum = SIMD3<Float>(maximum)

    let tx1 = (minimum.x - ray.origin.x) * inverseDirection.x
    let tx2 = (maximum.x - ray.origin.x) * inverseDirection.x

    var tmin = min(tx1, tx2)
    var tmax = max(tx1, tx2)

    let ty1 = (minimum.y - ray.origin.y) * inverseDirection.y
    let ty2 = (maximum.y - ray.origin.y) * inverseDirection.y

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    let tz1 = (minimum.z - ray.origin.z) * inverseDirection.z
    let tz2 = (maximum.z - ray.origin.z) * inverseDirection.z

    tmin = max(tmin, min(tz1, tz2))
    tmax = min(tmax, max(tz1, tz2))

    return tmax >= tmin ? tmin : nil
  }
}
