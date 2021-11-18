import Foundation
import MetalKit
import simd

/// A renderer that renders a `World`
public final class WorldRenderer: Renderer {
  // MARK: Private properties
  
  /// Render pipeline used for rendering world geometry.
  private var renderPipelineState: MTLRenderPipelineState
  
  /// The device used for rendering.
  private var device: MTLDevice
  /// The resources to use for rendering blocks.
  private var resources: ResourcePack.Resources
  /// The command queue used for rendering.
  private var commandQueue: MTLCommandQueue
  /// The array texture containing all of the block textures.
  private var arrayTexture: AnimatedArrayTexture
  
  /// The client to render for.
  private var client: Client
  
  /// Manages the world's meshes.
  private var worldMesh: WorldMesh
  
  // MARK: Init
  
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
    
    // Create world mesh
    worldMesh = WorldMesh(client.game.world, resources: resources)
    
    // Register event handler
    client.eventBus.registerHandler(handle(_:))
  }
  
  // MARK: Public methods
  
  /// Renders the world's blocks.
  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    var meshes = worldMesh.getMeshes()
    
    log.debug("meshes.count: \(meshes.count)")
    
    // Update animated textures
    arrayTexture.update(tick: client.game.tickScheduler.tickNumber, device: device, commandQueue: commandQueue)
    
    // Encode render pass
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    encoder.setVertexBuffer(worldToClipUniformsBuffer, offset: 0, index: 1)
    
    for i in 0..<meshes.count {
      try meshes[i].renderTransparentOpaque(renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
    
    for i in 0..<meshes.count {
      try meshes[i].renderTranslucent(viewedFrom: camera.position, sortTranslucent: true, renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
  }
  
  // MARK: Private methods
  
  private func handle(_ event: Event) {
    log.debug("Handling event: \(event)")
    switch event {
      case let event as World.Event.AddChunk:
        log.debug("Handling chunk add event")
        worldMesh.addChunk(event.chunk, at: event.position)
      case let event as JoinWorldEvent:
        log.debug("Creating new world mesh")
        worldMesh = WorldMesh(event.world, resources: resources)
      default:
        return
    }
  }
}
