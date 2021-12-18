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
    client.eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handle(event)
    }
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
    var stopwatch = Stopwatch(mode: .verbose, name: "WorldRenderer.render")
    
    stopwatch.startMeasurement("worldMesh.update")
    worldMesh.update(camera: camera, renderDistance: client.configuration.render.renderDistance)
    stopwatch.stopMeasurement("worldMesh.update")
    
    stopwatch.startMeasurement("arrayTexture.update")
    // Update animated textures
    arrayTexture.update(tick: client.game.tickScheduler.tickNumber, device: device, commandQueue: commandQueue)
    stopwatch.stopMeasurement("arrayTexture.update")
    
    stopwatch.startMeasurement("setup render pass")
    // Setup render pass
    encoder.setRenderPipelineState(renderPipelineState)
    encoder.setFragmentTexture(arrayTexture.texture, index: 0)
    stopwatch.stopMeasurement("setup render pass")
    
    stopwatch.startMeasurement("renderTransparentAndOpaque")
    // Render transparent and opaque geometry
    try worldMesh.mutateVisibleMeshes { _, mesh in
      try mesh.renderTransparentAndOpaque(renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
    stopwatch.stopMeasurement("renderTransparentAndOpaque")
    
    stopwatch.startMeasurement("renderTranslucent")
    // Render translucent geometry
    try worldMesh.mutateVisibleMeshes(fromBackToFront: true) { _, mesh in
      try mesh.renderTranslucent(viewedFrom: camera.position, sortTranslucent: true, renderEncoder: encoder, device: device, commandQueue: commandQueue)
    }
    stopwatch.stopMeasurement("renderTranslucent")
  }
  
  // MARK: Private methods
  
  private func handle(_ event: Event) {
    switch event {
      case let event as World.Event.ChunkComplete:
        worldMesh.addChunk(at: event.position)
        
      case let event as World.Event.RemoveChunk:
        worldMesh.removeChunk(at: event.position)
        
      case let event as World.Event.UpdateChunkLighting:
        let updatedSections = event.data.updatedSections
        var affectedSections: Set<ChunkSectionPosition> = []
        for y in updatedSections {
          let position = ChunkSectionPosition(event.position, sectionY: y)
          let affected = worldMesh.sectionsAffectedBySectionUpdate(at: position, onlyLighting: true)
          affectedSections.formUnion(affected)
        }
        
        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }
        
      case let event as World.Event.SetBlock:
        let affectedSections = worldMesh.sectionsAffectedBySectionUpdate(at: event.position.chunkSection)
        
        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }
        
      case let event as World.Event.UpdateChunk:
        var affectedSections: Set<ChunkSectionPosition> = []
        
        for sectionY in event.updatedSections {
          let position = ChunkSectionPosition(event.position, sectionY: sectionY)
          affectedSections.formUnion(worldMesh.sectionsAffectedBySectionUpdate(at: position))
        }
        
        for position in affectedSections {
          worldMesh.updateSection(at: position)
        }
        
      case _ as JoinWorldEvent:
        worldMesh = WorldMesh(client.game.world, cameraChunk: client.game.player.position.chunk, resources: resources)
        
      default:
        return
    }
  }
}
