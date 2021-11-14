import Foundation
import MetalKit

// TODO: remove when not needed anymore
var stopwatch = Stopwatch(mode: .summary)

// TODO: document render coordinator
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
      worldRenderer = try WorldRenderer(device: device, world: client.game.world, client: client, resources: client.resourcePack.vanillaResources, commandQueue: commandQueue)
    } catch {
      fatalError("Failed to create world renderer: \(error)")
    }
    
    do {
      entityRenderer = try EntityRenderer(device, commandQueue)
    } catch {
      fatalError("Failed to create entity renderer: \(error)")
    }
    
    // Create depth stencil state
    do {
      depthState = try Self.createDepthState(device: device)
    } catch {
      fatalError("Failed to create depth state: \(error)")
    }
    
    super.init()
    
    // Register listener for changing worlds
    client.eventBus.registerHandler { [weak self] event in
      guard let self = self else { return }
      self.handleClientEvent(event)
    }
  }
  
  // MARK: Render
  
  public func draw(in view: MTKView) {
    // TODO: Get the render pass descriptor as late as possible
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {
      log.warning("Failed to create command buffer and render encoder")
      return
    }
    
    updateCamera(client.game.player, view)
    let uniformsBuffer = camera.getUniformsBuffer()
    
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.counterClockwise)
    renderEncoder.setCullMode(.front)
    
    worldRenderer.draw(
      device: device,
      uniformsBuffer: uniformsBuffer,
      view: view,
      renderEncoder: renderEncoder,
      renderCommandBuffer: commandBuffer,
      camera: camera,
      commandQueue: commandQueue)
    
    entityRenderer.renderHitBoxes(
      view,
      uniformsBuffer: uniformsBuffer,
      camera: camera,
      nexus: client.game.nexus,
      device: device,
      renderEncoder: renderEncoder)
    
    guard let drawable = view.currentDrawable else {
      log.warning("Failed to get current drawable")
      return
    }
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  // MARK: Helper
  
  private static func createDepthState(device: MTLDevice) throws -> MTLDepthStencilState {
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .lessEqual
    depthDescriptor.isDepthWriteEnabled = true
    
    guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
      log.critical("Failed to create depth stencil state")
      throw RenderError.failedToCreateWorldDepthStencilState
    }
    
    return depthState
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
  
  private func updateCamera(_ player: Player, _ view: MTKView) {
    let aspect = Float(view.drawableSize.width / view.drawableSize.height)
    camera.setAspect(aspect)
    
    var eyePosition = SIMD3<Float>(player.position.smoothVector)
    eyePosition.y += 1.625 // TODO: don't hardcode this, use the player's hitbox
    
    camera.setPosition(eyePosition)
    camera.setRotation(playerLook: player.rotation)
    camera.cacheFrustum()
  }
  
  private func handleClientEvent(_ event: Event) {
    switch event {
      case let event as JoinWorldEvent:
        do {
          worldRenderer = try WorldRenderer(
            device: device,
            world: event.world,
            client: client,
            resources: client.resourcePack.vanillaResources,
            commandQueue: commandQueue)
        } catch {
          log.critical("Failed to create world renderer")
          client.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to create world renderer"))
        }
      case let event as ChangeFOVEvent:
        let fov = MathUtil.radians(from: Float(event.fovDegrees))
        camera.setFovY(fov)
      default:
        break
    }
  }
}
