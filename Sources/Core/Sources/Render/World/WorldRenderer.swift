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
    worldMesh = WorldMesh(client.game.world, cameraChunk: client.game.player.position.chunk, resources: resources)
    
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
    worldMesh.update(client.game.player.position.chunkSection, camera: camera)
    
    // Update animated textures
    arrayTexture.update(tick: client.game.tickScheduler.tickNumber, device: device, commandQueue: commandQueue)
    
    // Encode render pass
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    encoder.setVertexBuffer(worldToClipUniformsBuffer, offset: 0, index: 1)
    
    // Render transparent and opaque geometry
    try worldMesh.mutateVisibleMeshes { _, mesh in
      try mesh.renderTransparentAndOpaque(renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
    
    // Render translucent geometry
    try worldMesh.mutateVisibleMeshes(fromBackToFront: true) { _, mesh in
      try mesh.renderTranslucent(viewedFrom: camera.position, sortTranslucent: true, renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
  }
  
  // MARK: Private methods
  
  private func handle(_ event: Event) {
    switch event {
      case let event as World.Event.ChunkComplete:
        log.debug("Handling chunk complete event")
        worldMesh.addChunk(at: event.position)
      case _ as JoinWorldEvent:
        log.debug("Creating new world mesh")
        worldMesh = WorldMesh(client.game.world, cameraChunk: client.game.player.position.chunk, resources: resources)
      default:
        return
    }
  }
}
