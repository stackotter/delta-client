import Foundation
import MetalKit

/// Coordinates the rendering of the game (e.g. blocks and entities).
public final class RenderCoordinator: NSObject, MTKViewDelegate {
  // MARK: Public properties
  
  /// Statistics that measure the renderer's current performance.
  public var statistics: RenderStatistics
  
  // MARK: Private properties
  
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
  
  /// The time that the cpu started encoding the previous frame.
  private var previousFrameStartTime: Double = 0
  
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
    do {
      camera = try Camera(device)
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
    do {
      depthState = try MetalUtil.createDepthState(device: device)
    } catch {
      fatalError("Failed to create depth state: \(error)")
    }
    
    statistics = RenderStatistics(gpuCountersEnabled: false)
    
    super.init()
  }
  
  // MARK: Render
  
  public func draw(in view: MTKView) {
    let time = CFAbsoluteTimeGetCurrent()
    let frameTime = time - previousFrameStartTime
    previousFrameStartTime = time
    
    var stopwatch = Stopwatch(mode: .verbose, name: "RenderCoordinator.draw")
    
    stopwatch.startMeasurement("Get render pass descriptor")
    // Get current render pass descriptor
    guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
      log.error("Failed to get the current render pass descriptor")
      client.eventBus.dispatch(ErrorEvent(
        error: RenderError.failedToGetCurrentRenderPassDescriptor,
        message: "RenderCoordinator failed to get the current render pass descriptor"
      ))
      return
    }
    stopwatch.stopMeasurement("Get render pass descriptor")
    
    // The CPU start time if vsync was disabled
    let cpuStartTime = CFAbsoluteTimeGetCurrent()
    
    stopwatch.startMeasurement("Update camera")
    // Create world to clip uniforms buffer
    let uniformsBuffer = getCameraUniforms(view)
    stopwatch.stopMeasurement("Update camera")
    
    stopwatch.startMeasurement("Create render encoder")
    // Create command bugger
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      log.error("Failed to create command buffer")
      client.eventBus.dispatch(ErrorEvent(
        error: RenderError.failedToCreateCommandBuffer,
        message: "RenderCoordinator failed to create command buffer"
      ))
      return
    }
    
    // Create render encoder
    guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      log.error("Failed to create render encoder")
      client.eventBus.dispatch(ErrorEvent(
        error: RenderError.failedToCreateRenderEncoder,
        message: "RenderCoordinator failed to create render encoder"
      ))
      return
    }
    stopwatch.stopMeasurement("Create render encoder")
    
    // Configure the render encoder
    renderEncoder.setDepthStencilState(depthState)
    renderEncoder.setFrontFacing(.counterClockwise)
    renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
    
    switch client.configuration.render.mode {
      case .normal:
        renderEncoder.setCullMode(.front)
      case .wireframe:
        renderEncoder.setCullMode(.none)
        renderEncoder.setTriangleFillMode(.lines)
    }

    stopwatch.startMeasurement("Render world")
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
    stopwatch.stopMeasurement("Render world")

    stopwatch.startMeasurement("Render entities")
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
    stopwatch.stopMeasurement("Render entities")
    
    stopwatch.startMeasurement("Finish frame")
    // Finish measurements for render statistics
    let cpuFinishTime = CFAbsoluteTimeGetCurrent()
    
    // Finish encoding the frame
    guard let drawable = view.currentDrawable else {
      log.warning("Failed to get current drawable")
      return
    }
    
    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    
    self.statistics.addMeasurement(
      frameTime: frameTime,
      cpuTime: cpuFinishTime - cpuStartTime,
      gpuTime: nil)
    
    commandBuffer.commit()
    stopwatch.stopMeasurement("Finish frame")
  }
  
  // MARK: Helper
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
  
  /// Gets the camera uniforms for the current frame.
  /// - Parameter view: The view that is being rendered to. Used to get aspect ratio.
  /// - Returns: A buffer containing the uniforms.
  private func getCameraUniforms(_ view: MTKView) -> MTLBuffer {
    let aspect = Float(view.drawableSize.width / view.drawableSize.height)
    camera.setAspect(aspect)
    camera.setFovY(MathUtil.radians(from: client.configuration.render.fovY))
    
    client.game.accessPlayer { player in
      var eyePosition = SIMD3<Float>(player.position.smoothVector)
      eyePosition.y += 1.625 // TODO: don't hardcode this, use the player's eye height
      
      var cameraPosition = SIMD3<Float>(repeating: 0)
      
      var pitch = player.rotation.pitch
      var yaw = player.rotation.yaw
      
      switch player.camera.perspective {
        case .thirdPersonRear:
          cameraPosition.z += 3
          cameraPosition = simd_make_float3(SIMD4(cameraPosition, 1) * MatrixUtil.rotationMatrix(x: pitch) * MatrixUtil.rotationMatrix(y: Float.pi + yaw))
          cameraPosition += eyePosition
        case .thirdPersonFront:
          pitch = -pitch
          yaw += Float.pi
          
          cameraPosition.z += 3
          cameraPosition = simd_make_float3(SIMD4(cameraPosition, 1) * MatrixUtil.rotationMatrix(x: pitch) * MatrixUtil.rotationMatrix(y: Float.pi + yaw))
          cameraPosition += eyePosition
        case .firstPerson:
          cameraPosition = eyePosition
      }
      
      camera.setPosition(cameraPosition)
      camera.setRotation(xRot: pitch, yRot: yaw)
    }
    
    camera.cacheFrustum()
    return camera.getUniformsBuffer()
  }
}
