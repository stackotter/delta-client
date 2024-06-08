import DeltaCore
import FirebladeMath
import MetalKit

#if canImport(UIKit)
  import UIKit
#endif

/// The renderer for the GUI (chat, f3, scoreboard etc.).
public final class GUIRenderer: Renderer {
  static let scale: Float = 2

  var device: MTLDevice
  var font: Font
  var locale: MinecraftLocale
  var uniformsBuffer: MTLBuffer
  var pipelineState: MTLRenderPipelineState
  var profiler: Profiler<RenderingMeasurement>
  var previousUniforms: GUIUniforms?

  var client: Client

  var fontArrayTexture: MTLTexture
  var guiTexturePalette: GUITexturePalette
  var guiArrayTexture: MTLTexture
  var itemTexturePalette: TexturePalette
  var itemArrayTexture: MTLTexture
  var itemModelPalette: ItemModelPalette
  var blockArrayTexture: MTLTexture
  var blockModelPalette: BlockModelPalette
  var blockTexturePalette: TexturePalette

  var cache: [GUIElementMesh] = []

  public init(
    client: Client,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    profiler: Profiler<RenderingMeasurement>
  ) throws {
    self.client = client
    self.device = device
    self.profiler = profiler

    // Create array texture
    font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    locale = client.resourcePack.getDefaultLocale()

    let resources = client.resourcePack.vanillaResources
    let font = resources.fontPalette.defaultFont
    fontArrayTexture = try font.createArrayTexture(
      device: device,
      commandQueue: commandQueue
    )
    fontArrayTexture.label = "fontArrayTexture"

    guiTexturePalette = try GUITexturePalette(resources.guiTexturePalette)
    guiArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.guiTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    guiArrayTexture.label = "guiArrayTexture"

    itemTexturePalette = resources.itemTexturePalette
    itemArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.itemTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    itemArrayTexture.label = "itemArrayTexture"
    itemModelPalette = resources.itemModelPalette

    blockTexturePalette = resources.blockTexturePalette
    blockArrayTexture = try MetalTexturePalette.createArrayTexture(
      for: resources.blockTexturePalette,
      device: device,
      commandQueue: commandQueue,
      includeAnimations: false
    )
    blockArrayTexture.label = "blockArrayTexture"
    blockModelPalette = resources.blockModelPalette

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
    let scalingFactor = Self.scale * Self.screenScalingFactor()

    // Adjust scale per screen scale factor
    var uniforms = createUniforms(width, height, scalingFactor)
    if uniforms != previousUniforms || true {
      uniformsBuffer.contents().copyMemory(
        from: &uniforms,
        byteCount: MemoryLayout<GUIUniforms>.size
      )
      previousUniforms = uniforms
    }
    profiler.pop()

    // Create meshes
    let effectiveDrawableSize = Vec2i(
      Int(width / scalingFactor),
      Int(height / scalingFactor)
    )

    client.game.mutateGUIState { guiState in
      guiState.drawableSize = effectiveDrawableSize
      guiState.drawableScalingFactor = scalingFactor
    }

    let renderable = client.game.compileGUI(withFont: font, locale: locale, connection: nil)

    let meshes = try meshes(for: renderable)

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

  func meshes(for renderable: GUIElement.GUIRenderable) throws -> [GUIElementMesh] {
    var meshes: [GUIElementMesh]
    switch renderable.content {
      case let .text(wrappedLines, hangingIndent, color):
        let builder = TextMeshBuilder(font: font)
        meshes = try wrappedLines.compactMap { (line: String) in
          do {
            return try builder.build(
              line,
              fontArrayTexture: fontArrayTexture,
              color: color
            )
          } catch let error as LocalizedError {
            throw error.with("Text", line)
          }
        }
        for i in meshes.indices where i != 0 {
          meshes[i].position.x += hangingIndent
          meshes[i].position.y += Font.defaultCharacterHeight + 1
        }
      case let .sprite(descriptor):
        meshes = try [
          GUIElementMesh(
            sprite: descriptor,
            guiTexturePalette: guiTexturePalette,
            guiArrayTexture: guiArrayTexture
          )
        ]
      case let .item(itemId):
        meshes = try self.meshes(forItemWithId: itemId)
      case nil, .interactable, .background:
        if case let .background(color) = renderable.content {
          meshes = [
            GUIElementMesh(size: renderable.size, color: color)
          ]
        } else {
          meshes = []
        }
        meshes += try renderable.children.flatMap(meshes(for:))
    }
    meshes.translate(amount: renderable.relativePosition)
    return meshes
  }

  func meshes(forItemWithId itemId: Int) throws -> [GUIElementMesh] {
    guard let model = itemModelPalette.model(for: itemId) else {
      throw GUIRendererError.invalidItemId(itemId)
    }

    switch model {
      case let .layered(textures, _):
        return textures.map { texture in
          switch texture {
            case let .block(index):
              return GUIElementMesh(slice: index, texture: blockArrayTexture)
            case let .item(index):
              return GUIElementMesh(slice: index, texture: itemArrayTexture)
          }
        }
      case let .blockModel(modelId):
        guard let model = blockModelPalette.model(for: modelId, at: nil) else {
          log.warning("Missing block model of id \(modelId) (for item)")
          return []
        }

        // Get the block's transformation assuming that each block model part has the same
        // associated gui transformation (I don't see why this wouldn't always be true).
        var transformation: Mat4x4f
        if let transformsIndex = model.parts.first?.displayTransformsIndex {
          transformation = blockModelPalette.displayTransforms[transformsIndex].gui
        } else {
          transformation = MatrixUtil.identity
        }

        transformation *=
          MatrixUtil.translationMatrix([-0.5, -0.5, -0.5])
          * MatrixUtil.rotationMatrix(x: .pi)
          * MatrixUtil.rotationMatrix(y: -.pi / 4)
          * MatrixUtil.rotationMatrix(x: -.pi / 6)
          * MatrixUtil.scalingMatrix(9.76)
          * MatrixUtil.translationMatrix([8, 8, 8])

        var geometry = Geometry<BlockVertex>()
        var translucentGeometry = SortableMeshElement()
        BlockMeshBuilder(
          model: model,
          position: BlockPosition(x: 0, y: 0, z: 0),
          modelToWorld: transformation,
          culledFaces: [],
          lightLevel: LightLevel(sky: 15, block: 15),
          neighbourLightLevels: [:],
          tintColor: [1, 1, 1],
          blockTexturePalette: blockTexturePalette
        ).build(into: &geometry, translucentGeometry: &translucentGeometry)

        var vertices: [GUIVertex] = []
        vertices.reserveCapacity(geometry.vertices.count)
        for vertex in geometry.vertices + translucentGeometry.vertices {
          vertices.append(
            GUIVertex(
              position: [vertex.x, vertex.y],
              uv: [vertex.u, vertex.v],
              tint: [vertex.r, vertex.g, vertex.b, 1],
              textureIndex: vertex.textureIndex
            )
          )
        }

        var mesh = GUIElementMesh(
          size: [16, 16],
          arrayTexture: blockArrayTexture,
          vertices: .flatArray(vertices)
        )
        mesh.position = [0, 0]
        return [mesh]
      case .empty, .entity:
        return []
    }
  }

  static func optimizeMeshes(_ meshes: [GUIElementMesh]) throws -> [GUIElementMesh] {
    var textureToIndex: [String: Int] = [:]
    var boxes: [[(position: Vec2i, size: Vec2i)]] = []
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
    doIntersect(
      (position: mesh.position, size: mesh.size),
      (position: other.position, size: other.size)
    )
  }

  static func doIntersect(
    _ box: (position: Vec2i, size: Vec2i),
    _ other: (position: Vec2i, size: Vec2i)
  ) -> Bool {
    let pos1 = box.position
    let size1 = box.size
    let pos2 = other.position
    let size2 = other.size

    let overlapsX = abs((pos1.x + size1.x / 2) - (pos2.x + size2.x / 2)) * 2 < (size1.x + size2.x)
    let overlapsY = abs((pos1.y + size1.y / 2) - (pos2.y + size2.y / 2)) * 2 < (size1.y + size2.y)
    return overlapsX && overlapsY
  }

  static func combine(_ mesh: inout GUIElementMesh, _ other: GUIElementMesh) {
    var other = other
    normalizeMeshPosition(&mesh)
    normalizeMeshPosition(&other)
    mesh.vertices.append(contentsOf: other.vertices)
    mesh.size = Vec2i(
      max(mesh.size.x, other.size.x),
      max(mesh.size.y, other.size.y)
    )
  }

  /// Moves the mesh's vertices so that its position can be the origin.
  static func normalizeMeshPosition(_ mesh: inout GUIElementMesh) {
    if mesh.position == .zero {
      return
    }

    let position = Vec2f(mesh.position)
    mesh.vertices.mutateEach { vertex in
      vertex.position += position
    }

    mesh.position = .zero
    mesh.size &+= Vec2i(position)
  }

  /// Gets the scaling factor of the screen that Delta Client's currently getting rendered for.
  public static func screenScalingFactor() -> Float {
    // Higher density displays have higher scaling factors to keep content a similar real world
    // size across screens.
    #if canImport(AppKit)
      let screenScalingFactor = Float(NSApp.windows.first?.screen?.backingScaleFactor ?? 1)
    #elseif canImport(UIKit)
      let screenScalingFactor = Float(UIScreen.main.scale)
    #else
      #error("Unsupported platform, unknown screen scale factor")
    #endif
    return screenScalingFactor
  }

  func createUniforms(_ width: Float, _ height: Float, _ scale: Float) -> GUIUniforms {
    let transformation = Mat3x3f([
      [2 / width, 0, -1],
      [0, -2 / height, 1],
      [0, 0, 1],
    ])
    return GUIUniforms(screenSpaceToNormalized: transformation, scale: scale)
  }
}
