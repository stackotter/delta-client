import Foundation

/// An element of a ``SortableMesh``.
public struct SortableMeshElement {
  /// The element's unique id within its mesh.
  public var id: Int
  /// The vertex data.
  public var vertices: [BlockVertex] = []
  /// The vertex windings.
  public var indices: [UInt32] = []
  /// The position of the center of the mesh.
  public var centerPosition: SIMD3<Float>
  
  /// Create a new element.
  public init(id: Int = 0, vertices: [BlockVertex] = [], indices: [UInt32] = [], centerPosition: SIMD3<Float>) {
    self.id = id
    self.vertices = vertices
    self.indices = indices
    self.centerPosition = centerPosition
  }
  
  /// Create a new element with geometry.
  /// - Parameters:
  ///   - geometry: The element's geometry
  ///   - centerPosition: The position of the center of the element.
  public init(id: Int = 0, geometry: Geometry, centerPosition: SIMD3<Float>) {
    self.init(id: id, vertices: geometry.vertices, indices: geometry.indices, centerPosition: centerPosition)
  }
}

extension SortableMeshElement: Equatable {
  public static func == (lhs: SortableMeshElement, rhs: SortableMeshElement) -> Bool {
    return lhs.id == rhs.id
  }
}
