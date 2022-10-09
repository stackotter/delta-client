import Foundation

public enum RenderError: LocalizedError {
  /// Failed to create a metal texture array.
  case failedToCreateTextureArray
  /// Failed to get the Delta Core bundle.
  case failedToGetBundle
  /// Failed to find default.metallib in the bundle.
  case failedToLocateMetallib
  /// Failed to create a metal library from `default.metallib`.
  case failedToCreateMetallib(Error)
  /// Failed to load the shaders from the metallib.
  case failedToLoadShaders
  /// Failed to create the buffers that hold the world uniforms.
  case failedtoCreateWorldUniformBuffers
  /// Failed to create the render pipeline state for the world renderer.
  case failedToCreateWorldRenderPipelineState(Error)
  /// Failed to create the depth stencil state for the world renderer.
  case failedToCreateWorldDepthStencilState
  /// Failed to create the render pipeline state for the entity renderer.
  case failedToCreateEntityRenderPipelineState(Error)
  /// Failed to create the depth stencil state for the entity renderer.
  case failedToCreateEntityDepthStencilState
  /// Failed to create the block texture array.
  case failedToCreateBlockTextureArray(Error)
  /// Failed to create the render encoder.
  case failedToCreateRenderEncoder
  /// Failed to create the command buffer.
  case failedToCreateCommandBuffer
  /// Failed to create geometry buffers for the entity renderer.
  case failedToCreateEntityGeometryBuffers
  /// Failed to create a metal buffer.
  case failedToCreateBuffer(label: String?)
  /// Failed to get the current render pass descriptor for a frame.
  case failedToGetCurrentRenderPassDescriptor
  /// Failed to create an event for the gpu timer.
  case failedToCreateTimerEvent
  /// Failed to get the specified counter set (it is likely not supported by the selected device).
  case failedToGetCounterSet(_ rawValue: String)
  /// Failed to create the buffer used for sampling GPU counters.
  case failedToMakeCounterSampleBuffer(Error)
  /// Failed to sample the GPU counters used to calculate FPS.
  case failedToSampleCounters
  /// The current device does not support capturing a gpu trace and outputting to a file.
  case gpuTraceNotSupported
  /// Failed to start GPU frame capture.
  case failedToStartCapture(Error)
  
  public var errorDescription: String? {
    switch self {
      case .failedToCreateTextureArray:
        return "Failed to create a metal texture array."
      case .failedToGetBundle:
        return "Failed to get the Delta Core bundle.."
      case .failedToLocateMetallib:
        return "Failed to find default.metallib in the bundle."
      case .failedToCreateMetallib(let error):
        return """
        Failed to create a metal library from `default.metallib`.
        Reason: \(error.localizedDescription)
        """
      case .failedToLoadShaders:
        return "Failed to load the shaders from the metallib."
      case .failedtoCreateWorldUniformBuffers:
        return "Failed to create the buffers that hold the world uniforms."
      case .failedToCreateWorldRenderPipelineState(let error):
        return """
        Failed to create the render pipeline state for the world renderer.
        Reason: \(error.localizedDescription)
        """
      case .failedToCreateWorldDepthStencilState:
        return "Failed to create the depth stencil state for the entity renderer."
      case .failedToCreateEntityRenderPipelineState(let error):
        return """
        Failed to create the render pipeline state for the entity renderer.
        Reason: \(error.localizedDescription)
        """
      case .failedToCreateEntityDepthStencilState:
        return " Failed to create the depth stencil state for the entity renderer."
      case .failedToCreateBlockTextureArray(let error):
        return """
        Failed to create the block texture array.
        Reason: \(error.localizedDescription)
        """
      case .failedToCreateRenderEncoder:
        return "Failed to create the render encoder."
      case .failedToCreateCommandBuffer:
        return "Failed to create the command buffer."
      case .failedToCreateEntityGeometryBuffers:
        return "Failed to create geometry buffers for the entity renderer."
      case .failedToCreateBuffer(let label):
        return "Failed to create a metal buffer with label: \(label ?? "no label provided")."
      case .failedToGetCurrentRenderPassDescriptor:
        return "Failed to get the current render pass descriptor for a frame."
      case .failedToCreateTimerEvent:
        return "Failed to get the specified counter set (it is likely not supported by the selected device)."
      case .failedToGetCounterSet(let rawValue):
        return """
        Failed to get the specified counter set (it is likely not supported by the selected device).
        Raw value: \(rawValue)
        """
      case .failedToMakeCounterSampleBuffer(let error):
        return """
        Failed to create the buffer used for sampling GPU counters.
        Reason: \(error.localizedDescription)
        """
      case .failedToSampleCounters:
        return "Failed to sample the GPU counters used to calculate FPS."
      case .gpuTraceNotSupported:
        return "The current device does not support capturing a gpu trace and outputting to a file."
      case .failedToStartCapture(let error):
        return """
        Failed to start GPU frame capture.
        Reason: \(error.localizedDescription)
        """
    }
  }
}
