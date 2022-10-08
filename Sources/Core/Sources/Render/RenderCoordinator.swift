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

  /// The renderer for rendering the GUI.
  private var guiRenderer: GUIRenderer

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

  /// The current frame capture state (`nil` if no capture is in progress).
  private var captureState: CaptureState?
  
  /// The current state of user's hardware. Indicates device feature support.
  private var hardwareState: HardwareState

  /// The renderer profiler.
  private var profiler = Profiler<RenderingMeasurement>("Rendering")

  /// The number of frames rendered so far.
  private var frameCount = 0

  /// The longest a frame has taken to encode so far.
  private var longestFrame: Double = 0

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
    self.hardwareState = HardwareState(for: device)

    // Setup camera
    do {
      camera = try Camera(device)
    } catch {
      fatalError("Failed to create camera: \(error)")
    }

    // Create world renderer
    do {
      worldRenderer = try WorldRenderer(
        client: client,
        device: device,
        commandQueue: commandQueue,
        profiler: profiler
      )
    } catch {
      fatalError("Failed to create world renderer: \(error)")
    }

    do {
      guiRenderer = try GUIRenderer(
        client: client,
        device: device,
        commandQueue: commandQueue,
        profiler: profiler
      )
    } catch {
      fatalError("Failed to create GUI renderer: \(error)")
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

    profiler.push(.waitForRenderPassDescriptor)
    // Get current render pass descriptor
    guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
      log.error("Failed to get the current render pass descriptor")
      client.eventBus.dispatch(ErrorEvent(
        error: RenderError.failedToGetCurrentRenderPassDescriptor,
        message: "RenderCoordinator failed to get the current render pass descriptor"
      ))
      return
    }
    profiler.pop()

    // The CPU start time if vsync was disabled
    let cpuStartTime = CFAbsoluteTimeGetCurrent()

    profiler.push(.updateCamera)
    // Create world to clip uniforms buffer
    let uniformsBuffer = getCameraUniforms(view)
    profiler.pop()

    profiler.push(.createRenderCommandEncoder)
    // Create command buffer
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
    profiler.pop()

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

    profiler.push(.world)
    do {
      try worldRenderer.render(
        view: view,
        encoder: renderEncoder,
        commandBuffer: commandBuffer,
        worldToClipUniformsBuffer: uniformsBuffer,
        camera: camera
      )
    } catch {
      log.error("Failed to render world: \(error)")
      client.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to render world"))
      return
    }
    profiler.pop()

    profiler.push(.gui)
    do {
      try guiRenderer.render(
        view: view,
        encoder: renderEncoder,
        commandBuffer: commandBuffer,
        worldToClipUniformsBuffer: uniformsBuffer,
        camera: camera
      )
    } catch {
      log.error("Failed to render GUI: \(error)")
      client.eventBus.dispatch(ErrorEvent(error: error, message: "Failed to render GUI"))
      return
    }
    profiler.pop()

    profiler.push(.commitToGPU)
    // Finish measurements for render statistics
    let cpuFinishTime = CFAbsoluteTimeGetCurrent()

    // Finish encoding the frame
    guard let drawable = view.currentDrawable else {
      log.warning("Failed to get current drawable")
      return
    }

    renderEncoder.endEncoding()
    commandBuffer.present(drawable)

    let cpuElapsed = cpuFinishTime - cpuStartTime
    statistics.addMeasurement(
      frameTime: frameTime,
      cpuTime: cpuElapsed,
      gpuTime: nil
    )

    // Update statistics in gui
    guiRenderer.gui.renderStatistics = statistics

    commandBuffer.commit()
    profiler.pop()

    // Update frame capture state and stop current capture if necessary
    captureState?.framesRemaining -= 1
    if let captureState = captureState, captureState.framesRemaining == 0 {
      let captureManager = MTLCaptureManager.shared()
      captureManager.stopCapture()
      client.eventBus.dispatch(FinishFrameCaptureEvent(file: captureState.outputFile))

      self.captureState = nil
    }

    frameCount += 1
    profiler.endTrial()

    if frameCount % 60 == 0 {
      longestFrame = cpuElapsed
      profiler.printSummary()
      profiler.clear()
    }
  }

  /// Captures the specified number of frames into a GPU trace file.
  public func captureFrames(count: Int, to file: URL) throws {
    let captureManager = MTLCaptureManager.shared()

    guard captureManager.supportsDestination(.gpuTraceDocument) else {
      throw RenderError.gpuTraceNotSupported
    }

    let captureDescriptor = MTLCaptureDescriptor()
    captureDescriptor.captureObject = device
    captureDescriptor.destination = .gpuTraceDocument
    captureDescriptor.outputURL = file

    do {
      try captureManager.startCapture(with: captureDescriptor)
    } catch {
      throw RenderError.failedToStartCapture(error)
    }

    captureState = CaptureState(framesRemaining: count, outputFile: file)
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

      var pitch = player.rotation.smoothPitch
      var yaw = player.rotation.smoothYaw

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
