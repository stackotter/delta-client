import simd
import Foundation

struct GUIInventoryItem: GUIElement {
  var itemId: Int

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    guard let model = context.itemModelPalette.model(for: itemId) else {
      throw GUIRendererError.invalidItemId(itemId)
    }

    switch model {
      case let .layered(textures, _):
        return textures.map { texture in
          switch texture {
            case let .block(index):
              return GUIElementMesh(slice: index, texture: context.blockArrayTexture)
            case let .item(index):
              return GUIElementMesh(slice: index, texture: context.itemArrayTexture)
          }
        }
      case let .blockModel(modelId):
        guard let model = context.blockModelPalette.model(for: modelId, at: nil) else {
          log.warning("Missing block model of id \(modelId) (for item)")
          return []
        }

        // Get the block's transformation assuming that each block model part has the same
        // associated gui transformation (I don't see why this wouldn't always be true).
        var transformation: matrix_float4x4
        if let transformsIndex = model.parts.first?.displayTransformsIndex {
          transformation = context.blockModelPalette.displayTransforms[transformsIndex].gui
        } else {
          transformation = MatrixUtil.identity
        }

        transformation *= MatrixUtil.translationMatrix([-0.5, -0.5, -0.5])
        transformation *= MatrixUtil.rotationMatrix(x: .pi)
        transformation *= MatrixUtil.rotationMatrix(y: -.pi / 4)
        transformation *= MatrixUtil.rotationMatrix(x: -.pi / 6)

        var geometry = Geometry()
        var translucentGeometry = SortableMeshElement()
        BlockMeshBuilder(
          model: model,
          position: BlockPosition(x: 0, y: 0, z: 0),
          modelToWorld: transformation * MatrixUtil.scalingMatrix(9.9),
          culledFaces: [],
          lightLevel: LightLevel(sky: 15, block: 15),
          neighbourLightLevels: [:],
          tintColor: [1, 1, 1],
          blockTexturePalette: context.blockTexturePalette
        ).build(into: &geometry, translucentGeometry: &translucentGeometry)

        var vertices: [GUIVertex] = []
        vertices.reserveCapacity(geometry.vertices.count)
        for vertex in geometry.vertices {
          vertices.append(GUIVertex(
            position: [vertex.x, vertex.y],
            uv: [vertex.u, vertex.v],
            tint: [vertex.r, vertex.g, vertex.b],
            textureIndex: vertex.textureIndex
          ))
        }

        // TODO: Handle translucent block items

        var mesh = GUIElementMesh(
          size: [16, 16],
          arrayTexture: context.blockArrayTexture,
          vertices: vertices
        )
        mesh.position = [8, 8]
        return [mesh]
      case .empty, .entity:
        return []
    }
  }
}
