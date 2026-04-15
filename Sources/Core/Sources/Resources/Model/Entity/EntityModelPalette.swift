import Foundation

public enum EntityModelPaletteError: LocalizedError {
  case failedToDownloadJSONEntityModelPack(Error)
  case failedToUnzipJSONEntityModelPack(Error)
  case failedToDeserializeJSONEntityModel(URL, Error)
  case failedToCopyJSONEntityModels(sourceDirectory: URL, destinationDirectory: URL, Error)

  public var errorDescription: String? {
    switch self {
      case let .failedToDownloadJSONEntityModelPack(error):
        return "Failed to download default JSON Entity Model pack (\(error))."
      case let .failedToUnzipJSONEntityModelPack(error):
        return "Failed to unzip default JSON Entity Model pack (\(error))."
      case let .failedToDeserializeJSONEntityModel(file, error):
        return """
          Failed to deserialize JSON entity model (\(error)).
          File: \(file)
          """
      case let .failedToCopyJSONEntityModels(sourceDirectory, destinationDirectory, error):
        return """
          Failed to copy JSON entity models (\(error)).
          Source directory: \(sourceDirectory)
          Destination directory: \(destinationDirectory)
          """
    }
  }
}

public struct EntityModelPalette {
  // swiftlint:disable force_unwrapping
  static let jsonEntityModelPackDownloadURL = URL(
    string: "https://www.curseforge.com/api/v1/mods/360910/files/3268537/download"
  )!

  public var models: [Identifier: JSONEntityModel] = [:]

  /// Creates an empty entity model palette.
  public init(models: [Identifier: JSONEntityModel] = [:]) {
    self.models = models
  }

  /// Loads the JSON Entity Models contained in a specified directory.
  public static func load(from directory: URL, namespace: String) throws -> Self {
    let models = try JSONEntityModel.loadModels(from: directory, namespace: namespace)
    return EntityModelPalette(models: models)
  }

  /// Downloads the required JSON Entity Model files to the specified directory. Downloads them
  /// from the Template CEM project on CurseForge.
  public static func downloadJSONEntityModels(to directory: URL) throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
    let packZipFile = temporaryDirectory.appendingPathComponent("json_entity_models.zip")
    do {
      let data = try RequestUtil.data(contentsOf: Self.jsonEntityModelPackDownloadURL)
      try data.write(to: packZipFile)
    } catch {
      throw EntityModelPaletteError.failedToDownloadJSONEntityModelPack(error)
    }

    let packDirectory = temporaryDirectory.appendingPathComponent("json_entity_models")
    try? FileManager.default.removeItem(at: packDirectory)
    do {
      try FileManager.default.unzipItem(at: packZipFile, to: packDirectory, skipCRC32: true)
    } catch {
      throw EntityModelPaletteError.failedToUnzipJSONEntityModelPack(error)
    }

    let entityModelsDirectory = packDirectory.appendingPathComponent(
      "assets/minecraft/optifine/cem"
    )
    do {
      let files = try FileManager.default.contentsOfDirectory(
        at: entityModelsDirectory,
        includingPropertiesForKeys: nil,
        options: [.skipsSubdirectoryDescendants]
      )
      for file in files where file.pathExtension == "jem" {
        try FileManager.default.copyItem(
          at: file,
          to: directory.appendingPathComponent(file.lastPathComponent)
        )
      }
    } catch {
      throw EntityModelPaletteError.failedToCopyJSONEntityModels(
        sourceDirectory: entityModelsDirectory,
        destinationDirectory: directory,
        error
      )
    }
  }
}
