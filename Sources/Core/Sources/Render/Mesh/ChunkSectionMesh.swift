import Foundation
import MetalKit

/// A renderable mesh of a chunk section.
public struct ChunkSectionMesh {
  /// The mesh containing transparent and opaque blocks only. Doesn't need sorting.
  public var transparentAndOpaqueMesh: Mesh
  /// The mesh containing translucent blocks. Requires sorting when the player moves (clever stuff is done to minimise sorts in ``WorldRenderer``).
  public var translucentMesh: SortableMesh
  /// Whether the mesh contains fluids or not.
  public var containsFluids = false

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

  /// Updates the underlying buffers. Must call after changes to geometry and before rendering.
  /// - Parameters:
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use.
  public mutating func updateBuffers(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    try transparentAndOpaqueMesh.updateBuffers(device: device, commandQueue: commandQueue)
  }

  /// Encode the render commands for transparent and opaque mesh of this chunk section.
  /// - Parameter renderEncoder: Encoder for rendering geometry.
  public func renderTransparentAndOpaque(renderEncoder: MTLRenderCommandEncoder) throws {
    try transparentAndOpaqueMesh.render(into: renderEncoder)
  }

  /// Encode the render commands for translucent mesh of this chunk section.
  /// - Parameters:
  ///   - position: Position the mesh is viewed from. Used for sorting.
  ///   - sortTranslucent: Indicates whether sorting should be enabled for translucent mesh rendering.
  ///   - renderEncoder: Encoder for rendering geometry.
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use for creating buffers.
  public mutating func renderTranslucent(
    viewedFrom position: SIMD3<Float>,
    sortTranslucent: Bool,
    renderEncoder: MTLRenderCommandEncoder,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    try translucentMesh.render(
      viewedFrom: position,
      sort: sortTranslucent,
      encoder: renderEncoder,
      device: device,
      commandQueue: commandQueue
    )
  }
}
