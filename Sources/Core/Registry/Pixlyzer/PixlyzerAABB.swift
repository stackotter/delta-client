import Foundation

public struct PixlyzerAABB: Decodable {
  public var from: SingleOrMultiple<Float>
  public var to: SingleOrMultiple<Float>
  
  /// Convert a single of multiple to a vector.
  static func singleOrMultipleToVector(_ singleOrMultiple: SingleOrMultiple<Float>) throws -> SIMD3<Float> {
    switch singleOrMultiple {
      case let .single(value):
        return SIMD3<Float>(repeating: value)
      case let .multiple(values):
        guard values.count == 3 else {
          throw PixlyzerError.invalidAABBVertex(values)
        }
        return SIMD3<Float>(values)
    }
  }
}

extension AxisAlignedBoundingBox {
  public init(from pixlyzerAABB: PixlyzerAABB) throws {
    let from: SIMD3<Float> = try PixlyzerAABB.singleOrMultipleToVector(pixlyzerAABB.from)
    let to: SIMD3<Float> = try PixlyzerAABB.singleOrMultipleToVector(pixlyzerAABB.to)
    
    self.init(
      minimum: from,
      maximum: to)
  }
}
