struct InventoryItem: GUIElement {
  var itemId: Int

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    guard let item = RegistryStore.shared.itemRegistry.item(withId: itemId) else {
      throw GUIRendererError.invalidItemId(itemId)
    }

    var identifier = item.identifier
    identifier.name = "item/\(identifier.name)"

    guard let index = context.itemTexturePalette.textureIndex(for: identifier) else {
      // TODO: implement proper gui item rendering that uses item models from resource pack
      return []
    }

    return [
      GUIElementMesh(slice: index, texture: context.itemArrayTexture)
    ]
  }
}
