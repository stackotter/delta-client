import Foundation
import MetalKit

// TODO: remove when not needed anymore
var stopwatch = Stopwatch(mode: .summary)

// TODO: document render coordinator
public class RenderCoordinator: NSObject, RenderCoordinatorProtocol, MTKViewDelegate {
  private var client: Client
  
  private var camera: Camera
  private var worldRenderer: WorldRenderer
  
  private var commandQueue: MTLCommandQueue
  
  private var frame = 0
  
  private var device: MTLDevice
  
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
    camera = Camera()
    camera.setFovY(fovRadians)
    
    // Create world renderer
    do {
      worldRenderer = try WorldRenderer(device: device, world: client.game.world, client: client, resources: client.resourcePack.vanillaResources, commandQueue: commandQueue)
    } catch {
      fatalError("Failed to create world renderer")
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
    stopwatch.startMeasurement("whole frame")
    
    updateCamera(client.game.player, view)
    
    guard let worldRenderCommandBuffer = commandQueue.makeCommandBuffer()
    else {
      log.warning("Failed to create render command buffers")
      return
    }
    
    stopwatch.startMeasurement("world renderer")
    worldRenderer.draw(
      device: device,
      view: view,
      worldRenderCommandBuffer: worldRenderCommandBuffer,
      camera: camera,
      commandQueue: commandQueue)
    stopwatch.stopMeasurement("world renderer")
    
    guard let drawable = view.currentDrawable else {
      log.warning("Failed to get current drawable")
      return
    }
    
    worldRenderCommandBuffer.present(drawable)
    worldRenderCommandBuffer.commit()
    
    logFrame()
    stopwatch.stopMeasurement("whole frame")
  }
  
  // MARK: Helper
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
  
  private func updateCamera(_ player: Player, _ view: MTKView) {
    let aspect = Float(view.drawableSize.width / view.drawableSize.height)
    camera.setAspect(aspect)
    
    let currentPosition = player.position.vector
    let targetPosition = player.targetPosition.position.vector
    let tickProgress = Float(min(max((CFAbsoluteTimeGetCurrent() - client.game.tickScheduler.mostRecentTick) * 20, 0), 1))
    let interpolatedPosition = currentPosition + (targetPosition - currentPosition) * tickProgress
    var eyePosition = interpolatedPosition
    eyePosition.y += 1.625
    
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
  
  private func logFrame() {
    frame += 1
    if frame % 100 == 0 {
      stopwatch.summary(repeats: 100)
      stopwatch.reset()
      print("")
    }
  }
}
