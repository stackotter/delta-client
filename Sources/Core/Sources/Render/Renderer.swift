import Metal
import MetalKit

/// A protocol that renderers should conform to.
public protocol Renderer {
  /// Creates a renderer for the specified client.
  init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws

  /// Renders a frame.
  ///
  /// Should not call `encoder.endEncoding()` or `commandBuffer.commit()`. A render coordinator will
  /// manage the encoder and command buffer.
  mutating func render(
    view: MTKView,
    parallelEncoder: MTLParallelRenderCommandEncoder,
    depthState: MTLDepthStencilState,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws
}
