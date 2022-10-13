import Foundation

public struct PixlyzerAABB: Decodable {
  public var from: SingleOrMultiple<Double>
  public var to: SingleOrMultiple<Double>
  
  /// Convert a single of multiple to a vector.
  static func singleOrMultipleToVector(_ singleOrMultiple: SingleOrMultiple<Double>) throws -> SIMD3<Double> {
    switch singleOrMultiple {
      case let .single(value):
        return SIMD3<Double>(repeating: value)
      case let .multiple(values):
        guard values.count == 3 else {
          throw PixlyzerError.invalidAABBVertexLength(values.count)
        }
        return SIMD3<Double>(values)
    }
  }
}

extension AxisAlignedBoundingBox {
  public init(from pixlyzerAABB: PixlyzerAABB) throws {
    let from = try PixlyzerAABB.singleOrMultipleToVector(pixlyzerAABB.from)
    let to = try PixlyzerAABB.singleOrMultipleToVector(pixlyzerAABB.to)
    
    self.init(
      minimum: from,
      maximum: to)
  }
}
