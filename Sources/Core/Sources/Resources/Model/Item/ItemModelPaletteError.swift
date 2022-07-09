import Foundation

/// An error thrown by ``ItemModelPalette``.
public enum ItemModelPaletteError: LocalizedError {
  case failedToLoadJSON(file: URL, Error)
  case missingTexture(Identifier)
  case missingBlock(Identifier)
  case generatedModelMissingValuesForTextures
  case failedToLoadModel(Identifier, Error)
  case missingParent(Identifier)
  case missingModel(Identifier)
}
