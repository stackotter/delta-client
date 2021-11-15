import Metal
import MetalKit

/// A protocol that renderers should conform to.
public protocol Renderer {
  /// Creates a renderer for the specified client.
  init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws
  
  /// Renders a frame.
  ///
  /// Should not call `encoder.endEncoding()` of `commandBuffer.commit()`.
  /// A render coordinator should manage the encoder and command buffer.
  mutating func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws
}
