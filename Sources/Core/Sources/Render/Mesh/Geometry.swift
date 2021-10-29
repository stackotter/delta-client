import Foundation

/// The simplest representation of renderable geometry data. Just vertices and vertex winding.
public struct Geometry {
  /// Vertex data.
  var vertices: [Vertex] = []
  /// Vertex windings.
  var indices: [UInt32] = []
  
  public var isEmpty: Bool {
    return vertices.isEmpty || indices.isEmpty
  }
}
