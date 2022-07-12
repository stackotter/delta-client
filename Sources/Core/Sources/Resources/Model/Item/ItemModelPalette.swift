import Foundation

/// A palette containing item models loaded from a texture pack.
public struct ItemModelPalette {
  /// Item models indexed by item id.
  public var models: [ItemModel]

  /// Creates an item model palette with the given models (indexed by id).
  public init(_ models: [ItemModel] = []) {
    self.models = models
  }

  /// Loads the item models from the item models directory of a resource pack.
  /// - Parameters:
  ///   - directory: The directory to load item models from.
  ///   - itemTexturePalette: The palette containing all of the item textures.
  ///   - blockTexturePalette: The palette containing all of the block textures.
  ///   - blockModelPalette: The palette containing all of the block models.
  ///   - namespace: The namespace these models are within.
  /// - Throws: An error if any item models are missing or invalid.
  public static func load(
    from directory: URL,
    itemTexturePalette: TexturePalette,
    blockTexturePalette: TexturePalette,
    blockModelPalette: BlockModelPalette,
    namespace: String
  ) throws -> ItemModelPalette {
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      .filter { file in
        return file.pathExtension == "json"
      }

    var jsonModels: [Identifier: JSONItemModel] = [:]
    for file in files {
      let model: JSONItemModel
      do {
        let data = try Data(contentsOf: file)
        model = try JSONDecoder().decode(JSONItemModel.self, from: data)
      } catch {
        throw ItemModelPaletteError.failedToLoadJSON(file: file, error)
      }

      let identifier = Identifier(
        namespace: namespace,
        name: "item/" + file.deletingPathExtension().lastPathComponent
      )
      jsonModels[identifier] = model
    }

    var models: [ItemModel] = []
    for item in RegistryStore.shared.itemRegistry.items {
      let identifier = item.identifier
      guard let jsonModel = jsonModels[identifier] else {
        throw ItemModelPaletteError.missingModel(identifier)
      }

      let model: ItemModel
      do {
        model = try self.model(
          from: jsonModel,
          identifier: identifier,
          jsonModels: jsonModels,
          itemTexturePalette: itemTexturePalette,
          blockTexturePalette: blockTexturePalette,
          blockModelPalette: blockModelPalette
        )
      } catch {
        log.warning("Failed to load item model \(identifier): \(error)")
        model = .empty
      }

      models.append(model)
    }

    return ItemModelPalette(models)
  }

  private static func model(
    from jsonModel: JSONItemModel,
    identifier: Identifier,
    jsonModels: [Identifier: JSONItemModel],
    itemTexturePalette: TexturePalette,
    blockTexturePalette: TexturePalette,
    blockModelPalette: BlockModelPalette
  ) throws -> ItemModel {
    guard let parent = jsonModel.parent else {
      return ItemModel.empty
    }

    let jsonTransforms = jsonModel.display ?? JSONModelDisplayTransforms()
    let transforms = try ModelDisplayTransforms(from: jsonTransforms)

    if parent.name == "item/generated" {
      // Load generated model (an array of layered textures)
      guard let textures = jsonModel.textures else {
        throw ItemModelPaletteError.generatedModelMissingValuesForTextures
      }

      var texturesIndices: [ItemModelTexture] = []
      for i in 0... {
        guard let value = textures["layer\(i)"] else {
          break
        }

        let identifier = try Identifier(value)

        if let textureIndex = itemTexturePalette.textureIndex(for: identifier) {
          texturesIndices.append(.item(textureIndex))
        } else if let textureIndex = blockTexturePalette.textureIndex(for: identifier) {
          texturesIndices.append(.block(textureIndex))
        } else {
          throw ItemModelPaletteError.missingTexture(identifier)
        }
      }

      return .layered(textureIndices: texturesIndices, transforms: transforms)
    } else if parent.name == "builtin/entity" {
      return .entity(identifier, transforms: transforms)
    } else if parent.name.hasPrefix("block/") {
      guard let modelId = blockModelPalette.identifierToIndex[parent] else {
        throw ItemModelPaletteError.missingBlock(parent)
      }
      return .blockModel(id: modelId)
    } else {
      guard let parentJSONModel = jsonModels[parent] else {
        throw ItemModelPaletteError.missingParent(parent)
      }

      let jsonModel = parentJSONModel.merge(withChild: jsonModel)
      return try model(
        from: jsonModel,
        identifier: identifier,
        jsonModels: jsonModels,
        itemTexturePalette: itemTexturePalette,
        blockTexturePalette: blockTexturePalette,
        blockModelPalette: blockModelPalette
      )
    }
  }
}
