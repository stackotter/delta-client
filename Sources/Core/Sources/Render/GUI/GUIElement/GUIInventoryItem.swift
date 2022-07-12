struct GUIInventoryItem: GUIElement {
  var itemId: Int

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    guard let model = context.itemModelPalette.model(for: itemId) else {
      throw GUIRendererError.invalidItemId(itemId)
    }

    guard case let .layered(textures, _) = model else {
      // TODO: Implement rendering for other types of models
      return []
    }

    return textures.map { texture in
      switch texture {
        case .block(let index):
          return GUIElementMesh(slice: index, texture: context.blockArrayTexture)
        case .item(let index):
          return GUIElementMesh(slice: index, texture: context.itemArrayTexture)
      }
    }
  }
}
