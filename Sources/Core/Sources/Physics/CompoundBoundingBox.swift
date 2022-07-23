/// A collision shape made up of any number of axis aligned bounding boxes.
public struct CompoundBoundingBox: Codable {
  /// The shape's AABBs.
  public var aabbs: [AxisAlignedBoundingBox] = []

  /// Creates a new collision shape from an array of component AABBs.
  /// - Parameter aabbs: The AABBs that make up the shape.
  public init(_ aabbs: [AxisAlignedBoundingBox] = []) {
    self.aabbs = aabbs
  }

  /// Adds an AABB to the shape.
  /// - Parameter aabb: The AABB to add.
  public mutating func addAABB(_ aabb: AxisAlignedBoundingBox) {
    aabbs.append(aabb)
  }

  /// Adds an array of AABBs to the shape.
  /// - Parameter aabbs: The AABBs to add.
  public mutating func addAABBs(_ aabbs: [AxisAlignedBoundingBox]) {
    self.aabbs.append(contentsOf: aabbs)
  }

  /// Checks whether this shape intersects with the given AABB.
  /// - Parameter aabb: The AABB to check for intersection with.
  /// - Returns: `true` if the shape intersects with the AABB.
  public func intersects(with aabb: AxisAlignedBoundingBox) -> Bool {
    for shapeAABB in aabbs {
      if shapeAABB.intersects(with: aabb) {
        return true
      }
    }
    return false
  }

  /// Checks whether this shape intersects with the given ray.
  /// - Parameter ray: The ray to check for intersection with.
  /// - Returns: `true` if the shape intersects with the ray.
  public func intersects(with ray: Ray) -> Bool {
    for aabb in aabbs {
      if aabb.intersects(with: ray) {
        return true
      }
    }
    return false
  }

  /// Gets the distance at which a given ray intersects with this shape from the ray's origin.
  /// - Parameter ray: The ray to get the intersection distance of.
  /// - Returns: The intersection distance.
  public func intersectionDistance(with ray: Ray) -> Float? {
    let distances = aabbs.compactMap { aabb in
      return aabb.intersectionDistance(with: ray)
    }
    return distances.min()
  }

  /// Offsets the shape by a specified amount.
  /// - Parameter vector: The amount to offset the shape by.
  /// - Returns: The offset shape.
  public func offset(by vector: SIMD3<Double>) -> CompoundBoundingBox {
    var aabbs = aabbs
    for (i, aabb) in aabbs.enumerated() {
      aabbs[i] = aabb.offset(by: vector)
    }
    return CompoundBoundingBox(aabbs)
  }

  /// Adds another shape's AABBs to this shape.
  /// - Parameter other: The shape to combine with.
  public mutating func formUnion(_ other: CompoundBoundingBox) {
    aabbs.append(contentsOf: other.aabbs)
  }
}
