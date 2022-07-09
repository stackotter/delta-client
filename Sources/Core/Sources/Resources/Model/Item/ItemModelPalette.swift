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
  /// - Throws: An error if any item models are missing or invalid.
  public static func load(from directory: URL) throws -> ItemModelPalette {
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
      .filter { file in
        return file.pathExtension == "json"
      }

    for file in files {
      do {
        let data = try Data(contentsOf: file)
        let model = try JSONDecoder().decode(JSONItemModel.self, from: data)
        _ = model
      } catch {
        throw ItemModelPaletteError.failedToLoadJSON(file: file, error)
      }
    }

    return ItemModelPalette()
  }
}
