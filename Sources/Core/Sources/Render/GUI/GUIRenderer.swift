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

  var cache: [GUIElementMesh] = []

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
    if uniforms != previousUniforms || true {
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

    let optimizedMeshes = try Self.optimizeMeshes(meshes)

    for (i, var mesh) in optimizedMeshes.enumerated() {
      if i < cache.count {
        let previousMesh = cache[i]
        if (previousMesh.vertexBuffer?.length ?? 0) >= mesh.requiredVertexBufferSize {
          mesh.vertexBuffer = previousMesh.vertexBuffer
          mesh.uniformsBuffer = previousMesh.uniformsBuffer
        } else {
          mesh.uniformsBuffer = previousMesh.uniformsBuffer
        }

        try mesh.render(into: encoder, with: device)
        cache[i] = mesh
      } else {
        try mesh.render(into: encoder, with: device)
        cache.append(mesh)
      }
    }
    profiler.pop()
  }

  static func optimizeMeshes(_ meshes: [GUIElementMesh]) throws -> [GUIElementMesh] {
    var textureToIndex: [String: Int] = [:]
    var boxes: [[(position: SIMD2<Int>, size: SIMD2<Int>)]] = []
    var combinedMeshes: [GUIElementMesh] = []

    for mesh in meshes {
      var texture = "textureless"
      if let arrayTexture = mesh.arrayTexture {
        guard let label = arrayTexture.label else {
          throw GUIRendererError.textureMissingLabel
        }
        texture = label
      }

      // If the mesh's texture's current layer is below a layer that this mesh overlaps with, then
      // force a new layer to be created
      let box = (position: mesh.position, size: mesh.size)
      if let index = textureToIndex[texture] {
        let higherLayers = textureToIndex.values.filter { $0 > index }
        var done = false
        for layer in higherLayers {
          if doIntersect(mesh, combinedMeshes[layer]) {
            for otherBox in boxes[layer] {
              if doIntersect(box, otherBox) {
                textureToIndex[texture] = nil
                done = true
                break
              }
            }
            if done {
              break
            }
          }
        }
      }

      if let index = textureToIndex[texture] {
        combine(&combinedMeshes[index], mesh)
        boxes[index].append(box)
      } else {
        textureToIndex[texture] = combinedMeshes.count
        combinedMeshes.append(mesh)
        boxes.append([box])
      }
    }

    return combinedMeshes
  }

  static func doIntersect(_ mesh: GUIElementMesh, _ other: GUIElementMesh) -> Bool {
    doIntersect((position: mesh.position, size: mesh.size), (position: other.position, size: other.size))
  }

  static func doIntersect(
    _ box: (position: SIMD2<Int>, size: SIMD2<Int>),
    _ other: (position: SIMD2<Int>, size: SIMD2<Int>)
  ) -> Bool {
    let pos1 = box.position
    let size1 = box.size
    let pos2 = other.position
    let size2 = other.size

    let overlapsX = abs((pos1.x + size1.x/2) - (pos2.x + size2.x/2)) * 2 < (size1.x + size2.x)
    let overlapsY = abs((pos1.y + size1.y/2) - (pos2.y + size2.y/2)) * 2 < (size1.y + size2.y)
    return overlapsX && overlapsY
  }

  static func combine(_ mesh: inout GUIElementMesh, _ other: GUIElementMesh) {
    var other = other
    normalizeMeshPosition(&mesh)
    normalizeMeshPosition(&other)
    mesh.vertices.append(contentsOf: other.vertices)
    mesh.size = simd_max(mesh.size, other.size)
  }

  /// Moves the mesh's vertices so that its position can be the origin.
  static func normalizeMeshPosition(_ mesh: inout GUIElementMesh) {
    if mesh.position == .zero {
      return
    }

    let position = SIMD2<Float>(mesh.position)
    mesh.vertices.mutateEach { vertex in
      vertex.position += position
    }

    mesh.position = .zero
    mesh.size &+= SIMD2(position)
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
