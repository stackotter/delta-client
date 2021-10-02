import Foundation
import MetalKit

/// A mesh that can be sorted after the initial preparation.
///
/// Use for translucent meshes. Only really designed for grid-aligned objects.
public struct SortableMesh {
  /// Distinct mesh elements that should be rendered in order of distance.
  public var elements: [SortableMeshElement] = []
  
  /// The mesh may be empty even if this is false if all of the elements contain no geometry.
  public var isEmpty: Bool {
    return elements.isEmpty
  }
  
  private var underlyingMesh: Mesh
  
  /// Creates a new sortable mesh.
  /// - Parameters:
  ///   - elements: Distinct mesh elements that should be rendered in order of distance.
  ///   - uniforms: The mesh's uniforms.
  public init(_ elements: [SortableMeshElement] = [], uniforms: Uniforms) {
    self.elements = elements
    underlyingMesh = Mesh()
    underlyingMesh.uniforms = uniforms
  }
  
  /// Removes all elements from the mesh.
  public mutating func clear() {
    elements = []
    underlyingMesh.clearGeometry()
    underlyingMesh.invalidateBuffers(keepUniformsBuffer: true)
  }
  
  /// Add an element to the mesh.
  public mutating func add(_ element: SortableMeshElement) {
    elements.append(element)
  }
  
  /// Encode the render commands for this mesh.
  /// - Parameters:
  ///   - position: The position to sort from.
  ///   - sort: If `false`, the mesh will not be sorted and the previous one will be rendered (unless no previous mesh has been rendered).
  ///   - encoder: The encoder to encode the render commands into.
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use when creating buffers.
  public mutating func render(
    viewedFrom position: SIMD3<Float>,
    sort: Bool,
    encoder: MTLRenderCommandEncoder,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    if underlyingMesh.isEmpty && elements.isEmpty {
      return
    }
    
    if sort || underlyingMesh.isEmpty {
      underlyingMesh.clearGeometry()
      // TODO: reuse vertices from mesh and just recreate winding
      // Sort elements by distance in descending order.
      elements = elements.sorted(by: {
        let squaredDistance1 = distance_squared(position, $0.centerPosition)
        let squaredDistance2 = distance_squared(position, $1.centerPosition)
        return squaredDistance1 > squaredDistance2
      })
      
      for element in elements {
        let windingOffset = UInt32(underlyingMesh.vertices.count)
        underlyingMesh.vertices.append(contentsOf: element.vertices)
        for index in element.indices {
          underlyingMesh.indices.append(index + windingOffset)
        }
      }
      
      underlyingMesh.invalidateBuffers(keepUniformsBuffer: true)
    }
    
    // Could be reached if all elements contain no geometry
    if underlyingMesh.isEmpty {
      return
    }
    
    try underlyingMesh.render(into: encoder, with: device, commandQueue: commandQueue)
  }
}
