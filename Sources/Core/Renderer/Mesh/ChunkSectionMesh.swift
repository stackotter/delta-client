import FirebladeMath
import Foundation
import MetalKit

/// A renderable mesh of a chunk section.
public struct ChunkSectionMesh {
  /// The mesh containing transparent and opaque blocks only. Doesn't need sorting.
  public var transparentAndOpaqueMesh: Mesh<BlockVertex, ChunkUniforms>
  /// The mesh containing translucent blocks. Requires sorting when the player moves (clever stuff is done to minimise sorts in ``WorldRenderer``).
  public var translucentMesh: SortableMesh
  /// Whether the mesh contains fluids or not.
  public var containsFluids = false

  public var isEmpty: Bool {
    return transparentAndOpaqueMesh.isEmpty && translucentMesh.isEmpty
  }

  /// Create a new chunk section mesh.
  public init(_ uniforms: ChunkUniforms) {
    transparentAndOpaqueMesh = Mesh<BlockVertex, ChunkUniforms>(uniforms: uniforms)
    translucentMesh = SortableMesh(uniforms: uniforms)
  }

  /// Clear the mesh's geometry and invalidate its buffers. Leaves GPU buffers intact for reuse.
  public mutating func clearGeometry() {
    transparentAndOpaqueMesh.clearGeometry()
    translucentMesh.clear()
  }

  /// Encode the render commands for transparent and opaque mesh of this chunk section.
  /// - Parameters:
  ///   - renderEncoder: Encoder for rendering geometry.
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use for creating buffers.
  public mutating func renderTransparentAndOpaque(
    renderEncoder: MTLRenderCommandEncoder,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    try transparentAndOpaqueMesh.render(
      into: renderEncoder, with: device, commandQueue: commandQueue)
  }

  /// Encode the render commands for translucent mesh of this chunk section.
  /// - Parameters:
  ///   - position: Position the mesh is viewed from. Used for sorting.
  ///   - sortTranslucent: Indicates whether sorting should be enabled for translucent mesh rendering.
  ///   - renderEncoder: Encoder for rendering geometry.
  ///   - device: The device to use.
  ///   - commandQueue: The command queue to use for creating buffers.
  public mutating func renderTranslucent(
    viewedFrom position: Vec3f,
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
