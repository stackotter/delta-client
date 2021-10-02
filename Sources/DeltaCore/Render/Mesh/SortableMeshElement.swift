import Foundation

/// An element of a ``SortableMesh``.
public struct SortableMeshElement {
  /// The vertex data.
  public var vertices: [Vertex] = []
  /// The vertex windings.
  public var indices: [UInt32] = []
  /// The position of the center of the mesh.
  public var centerPosition: SIMD3<Float>
  
  /// Create a new element.
  public init(vertices: [Vertex] = [], indices: [UInt32] = [], centerPosition: SIMD3<Float>) {
    self.vertices = vertices
    self.indices = indices
    self.centerPosition = centerPosition
  }
  
  /// Create a new element with geometry.
  /// - Parameters:
  ///   - geometry: The element's geometry
  ///   - centerPosition: The position of the center of the element.
  public init(geometry: Geometry, centerPosition: SIMD3<Float>) {
    self.init(vertices: geometry.vertices, indices: geometry.indices, centerPosition: centerPosition)
  }
}
