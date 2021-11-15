import Foundation
import MetalKit
import simd

/// A renderer that renders a `World`
public struct WorldRenderer: Renderer {
  /// Render pipeline used for rendering world geometry.
  var renderPipelineState: MTLRenderPipelineState
  
  /// The resources to use for rendering blocks.
  var resources: ResourcePack.Resources
  /// The array texture containing all of the block textures.
  var arrayTexture: AnimatedArrayTexture
  
  /// The client to render for.
  var client: Client
  
  /// The device used for rendering.
  var device: MTLDevice
  /// The command queue used for rendering.
  var commandQueue: MTLCommandQueue
  
  /// Creates a new world renderer.
  public init(client: Client, device: MTLDevice, commandQueue: MTLCommandQueue) throws {
    self.device = device
    self.client = client
    self.commandQueue = commandQueue
    
    // Load shaders
    let library = try MetalUtil.loadDefaultLibrary(device)
    let vertexFunction = try MetalUtil.loadFunction("chunkVertexShader", from: library)
    let fragmentFunction = try MetalUtil.loadFunction("chunkFragmentShader", from: library)
    
    // Create block palette array texture.
    resources = client.resourcePack.vanillaResources
    arrayTexture = try AnimatedArrayTexture(palette: resources.blockTexturePalette, device: device, commandQueue: commandQueue)
    
    // Create pipeline
    renderPipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "dev.stackotter.delta-client.WorldRenderer",
      vertexFunction: vertexFunction,
      fragmentFunction: fragmentFunction,
      blendingEnabled: true)
  }
  
  /// Renders the world's blocks.
  public mutating func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Update animated textures
    arrayTexture.update(tick: client.game.tickScheduler.tickNumber, device: device, commandQueue: commandQueue)
    
    // Encode render pass
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    encoder.setVertexBuffer(worldToClipUniformsBuffer, offset: 0, index: 1)
  }
}
