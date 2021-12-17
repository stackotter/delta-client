import Foundation
import MetalKit

/// Coordinates the rendering of the game (e.g. blocks and entities).
public class RenderCoordinator: NSObject, RenderCoordinatorProtocol, MTKViewDelegate {
  /// The client to render.
  private var client: Client
  
  /// The renderer for the current world. Only renders blocks.
  private var worldRenderer: WorldRenderer
  /// The renderer for rendering entities.
  private var entityRenderer: EntityRenderer

  /// The camera that is rendered from.
  private var camera: Camera
  /// The device used to render.
  private var device: MTLDevice
  
  /// The depth stencil state. It's the same for every renderer so it's just made once here.
  private var depthState: MTLDepthStencilState
  /// The command queue.
  private var commandQueue: MTLCommandQueue
  
  // MARK: Init
  
  /// Creates a render coordinator.
  /// - Parameter client: The client to render for.
  public required init(_ client: Client) {
    // TODO: get rid of fatalErrors in RenderCoordinator
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Failed to get metal device")
    }
    
    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("Failed to make render command queue")
    }
    
    self.client = client
    self.device = device
    self.commandQueue = commandQueue
    
    // Setup camera
    let fovDegrees: Float = 90
    let fovRadians = fovDegrees / 180 * Float.pi
    do {
      camera = try Camera(device)
      camera.setFovY(fovRadians)
    } catch {
      fatalError("Failed to create camera: \(error)")
    }
    
    // Create world renderer
    do {
      worldRenderer = try WorldRenderer(client: client, device: device, commandQueue: commandQueue)
    } catch {
      fatalError("Failed to create world renderer: \(error)")
    }
    
    do {
      entityRenderer = try EntityRenderer(client: client, device: device, commandQueue: commandQueue)
    } catch {
      fatalError("Failed to create entity renderer: \(error)")
    }
    
    // Create depth stencil state
    depthState = try! MetalUtil.createDepthState(device: device)
    
    super.init()
    
    // Register listener for changing worlds
    client.eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handleClientEvent(event)
    }
  }
  
  // MARK: Render
  
  public func draw(in view: MTKView) {
    // Create world to clip uniforms buffer
    let uniformsBuffer = getCameraUniforms(view)
    
    // TODO: Get the render pass descriptor as late as possible
    
    // Create render encoder
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {
      log.error("Failed to create command buffer and render encoder")
      client.eventBus.dispatch(ErrorEvent(
        error: RenderError.failedToCreateRenderEncoder("RenderCoordinator"),
        message: "RenderCoordinator failed to create command buffer and render encoder"))
      return
    }
    
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.counterClockwise)
    renderEncoder.setCullMode(.front)
    renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)

    // Render world
    do {
      try worldRenderer.render(
        view: view,
        encoder: renderEncoder,
        commandBuffer: commandBuffer,
        worldToClipUniformsBuffer: uniformsBuffer,
        camera: camera)
    } catch {
      log.error("Failed to render world: \(error)")
      client.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to render world"))
      return
    }

    // Render entities
    do {
      try entityRenderer.render(
        view: view,
        encoder: renderEncoder,
        commandBuffer: commandBuffer,
        worldToClipUniformsBuffer: uniformsBuffer,
        camera: camera)
    } catch {
      log.error("Failed to render entities: \(error)")
      client.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to render entities"))
      return
    }
    
    // Finish encoding the frame
    guard let drawable = view.currentDrawable else {
      log.warning("Failed to get current drawable")
      return
    }
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  // MARK: Helper
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
  
  /// Gets the camera uniforms for the current frame.
  /// - Parameter view: The view that is being rendered to. Used to get aspect ratio.
  /// - Returns: A buffer containing the uniforms.
  private func getCameraUniforms(_ view: MTKView) -> MTLBuffer {
    let aspect = Float(view.drawableSize.width / view.drawableSize.height)
    camera.setAspect(aspect)
    
    let player = client.game.player
    var eyePosition = SIMD3<Float>(player.position.smoothVector)
    eyePosition.y += 1.625 // TODO: don't hardcode this, use the player's hitbox
    
    camera.setPosition(eyePosition)
    camera.setRotation(playerLook: player.rotation)
    camera.cacheFrustum()
    return camera.getUniformsBuffer()
  }
  
  /// Handle events received from the client.
  private func handleClientEvent(_ event: Event) {
    switch event {
      case let event as ChangeFOVEvent:
        // TODO: don't use events to update the fov
        let fov = MathUtil.radians(from: Float(event.fovDegrees))
        camera.setFovY(fov)
      default:
        break
    }
  }
}
