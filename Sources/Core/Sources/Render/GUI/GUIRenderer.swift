import MetalKit

#if os(iOS)
import UIKit
#endif

/// The renderer for the GUI (chat, f3, scoreboard etc.).
public final class GUIRenderer: Renderer {
  var device: MTLDevice
  var font: Font
  var scale: Float = 2
  var uniformsBuffer: MTLBuffer
  var pipelineState: MTLRenderPipelineState
  var gui: GUI
  var profiler: Profiler<RenderingMeasurement>
  var previousUniforms: GUIUniforms?

  public init(
    client: Client,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.device = device
    self.profiler = profiler

    // Create array texture
    font = client.resourcePack.vanillaResources.fontPalette.defaultFont

    // Create uniforms buffer
    uniformsBuffer = try MetalUtil.makeBuffer(
      device,
      length: MemoryLayout<GUIUniforms>.stride,
      options: []
    )

    // Create pipeline state
    let library = try MetalUtil.loadDefaultLibrary(device)
    pipelineState = try MetalUtil.makeRenderPipelineState(
      device: device,
      label: "GUIRenderer",
      vertexFunction: try MetalUtil.loadFunction("guiVertex", from: library),
      fragmentFunction: try MetalUtil.loadFunction("guiFragment", from: library),
      blendingEnabled: true
    )

    gui = try GUI(
      client: client,
      device: device,
      commandQueue: commandQueue,
      profiler: profiler
    )
  }

  public func render(
    view: MTKView,
    encoder: MTLRenderCommandEncoder,
    commandBuffer: MTLCommandBuffer,
    worldToClipUniformsBuffer: MTLBuffer,
    camera: Camera
  ) throws {
    // Construct uniforms
    profiler.push(.updateUniforms)
    let drawableSize = view.drawableSize
    let width = Float(drawableSize.width)
    let height = Float(drawableSize.height)
    let scale = Self.adjustScale(scale)

    // Adjust scale per screen scale factor
    var uniforms = createUniforms(width, height, scale)
    if uniforms != previousUniforms {
      uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
      previousUniforms = uniforms
    }
    profiler.pop()

    // Create meshes
    let meshes = try gui.meshes(
      effectiveDrawableSize: SIMD2([width / scale, height / scale])
    )

    profiler.push(.encode)
    // Set vertex buffers
    encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)

    // Set pipeline
    encoder.setRenderPipelineState(pipelineState)

    for var mesh in meshes {
      try mesh.render(into: encoder, with: device)
    }
    profiler.pop()
  }

  static func adjustScale(_ scale: Float) -> Float {
    // Adjust scale per screen scale factor
    #if os(macOS)
    let screenScaleFactor = Float(NSApp.windows.first?.screen?.backingScaleFactor ?? 1)
    #elseif os(iOS)
    let screenScaleFactor = Float(UIScreen.main.scale)
    #else
    #error("Unsupported platform, unknown screen scale factor")
    #endif
    return screenScaleFactor * scale
  }

  func createUniforms(_ width: Float, _ height: Float, _ scale: Float) -> GUIUniforms {
    let transformation = matrix_float3x3([
      [2 / width, 0, -1],
      [0, -2 / height, 1],
      [0, 0, 1]
    ])
    return GUIUniforms(screenSpaceToNormalized: transformation, scale: scale)
  }
}
