import Foundation
import simd

/// An axis aligned bounding box used for efficient collisions and visibility checks.
public struct AxisAlignedBoundingBox: Codable {
  /// The minimum vertex of the bounding box.
  public var minimum: SIMD3<Float>
  /// The maximum vertex of the bounding box.
  public var maximum: SIMD3<Float>
  
  /// Create a new axis aligned bounding box with given minimum and maximum vertices.
  /// - Parameters:
  ///   - minimum: The minimum vertex.
  ///   - maximum: The maximum vertex.
  public init(minimum: SIMD3<Float>, maximum: SIMD3<Float>) {
    self.minimum = minimum
    self.maximum = maximum
  }
  
  /// Create a new axis aligned bounding box at a position with a given size.
  /// - Parameters:
  ///   - position: The position of the bounding box.
  ///   - size: The size of the bounding box. Must be positive. The absolute value is taken just in case.
  public init(position: SIMD3<Float>, size: SIMD3<Float>) {
    self.minimum = position
    self.maximum = position + abs(size)
  }
  
  
  /// Get an array containing all 8 of this bounding box's vertices.
  /// - Returns: This bounding box's vertices.
  public func getVertices() -> [SIMD3<Float>] {
    let bfl = minimum
    let bfr = SIMD3<Float>(maximum.x, minimum.y, minimum.z)
    let tfl = SIMD3<Float>(minimum.x, maximum.y, minimum.z)
    let tfr = SIMD3<Float>(maximum.x, maximum.y, minimum.z)
    
    let bbl = SIMD3<Float>(minimum.x, minimum.y, maximum.z)
    let bbr = SIMD3<Float>(maximum.x, minimum.y, maximum.z)
    let tbl = SIMD3<Float>(minimum.x, maximum.y, maximum.z)
    let tbr = maximum
    
    return [bfl, bfr, tfl, tfr, bbl, bbr, tbl, tbr]
  }
}
