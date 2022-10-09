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
  
  public var errorDescription: String? {
    switch self {
      case .failedToLoadJSON(let file, let error):
        return """
        Failed to load JSON.
        File URL: \(file.absoluteString)
        Reason: \(error.localizedDescription)
        """
      case .missingTexture(let identifier):
        return "Missing texture with identifier: `\(identifier.description)`"
      case .missingBlock(let identifier):
        return "Missing block with identifier: `\(identifier.description)`"
      case .generatedModelMissingValuesForTextures:
        return "Generated model missing values for textures"
      case .failedToLoadModel(let identifier, let error):
        return """
        Failed to load model with identifier: `\(identifier.description)`.
        Reason: \(error.localizedDescription)
        """
      case .missingParent(let identifier):
        return "Missing parent with identifier: `\(identifier.description)`"
      case .missingModel(let identifier):
        return "Missing model with identifier: `\(identifier.description)`"
    }
  }
}
