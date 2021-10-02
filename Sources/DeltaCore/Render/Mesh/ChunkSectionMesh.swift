import Foundation
import MetalKit

/// A renderable mesh of a chunk section.
public struct ChunkSectionMesh {
  /// The mesh containing transparent and opaque blocks only. Doesn't need sorting.
  public var transparentAndOpaqueMesh: Mesh
  /// The mesh containing translucent blocks. Requires sorting when the player moves (clever stuff is done to minimise sorts in ``WorldRenderer``).
  public var translucentMesh: SortableMesh
  
  public var isEmpty: Bool {
    return transparentAndOpaqueMesh.isEmpty && translucentMesh.isEmpty
  }
  
  /// Create a new chunk section mesh.
  public init(_ uniforms: Uniforms) {
    transparentAndOpaqueMesh = Mesh()
    transparentAndOpaqueMesh.uniforms = uniforms
    translucentMesh = SortableMesh(uniforms: uniforms)
  }
  
  /// Clear the mesh's geometry and invalidate its buffers. Leaves GPU buffers intact for reuse.
  public mutating func clearGeometry() {
    transparentAndOpaqueMesh.clearGeometry()
    translucentMesh.clear()
  }
  
  /// Encode the render commands for this chunk section.
  /// - Parameters:
  ///   - position: Position the mesh is viewed from. Used for sorting.
  ///   - sortTranslucent: Whether the translucent mesh should be sorted or not.
  ///   - transparentAndOpaqueEncoder: Encoder for rendering transparent and opaque geometry.
  ///   - translucentEncoder: Encoder for rendering translucent geometry.
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use for creating buffers.
  public mutating func render(
    viewedFrom position: SIMD3<Float>,
    sortTranslucent: Bool,
    transparentAndOpaqueEncoder: MTLRenderCommandEncoder,
    translucentEncoder: MTLRenderCommandEncoder,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    try transparentAndOpaqueMesh.render(into: transparentAndOpaqueEncoder, with: device, commandQueue: commandQueue)
    try translucentMesh.render(viewedFrom: position, sort: sortTranslucent, encoder: translucentEncoder, device: device, commandQueue: commandQueue)
  }
}
