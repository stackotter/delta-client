import Metal
import MetalKit

/// A protocol that renderers should conform to.
public protocol Renderer {
  /// Renders a frame.
  ///
  /// Should not call `renderEncoder.endEncoding()` or `commandBuffer.commit()`.
  /// A render coordinator should will manage the encoder and command buffer.
  mutating func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws
}
