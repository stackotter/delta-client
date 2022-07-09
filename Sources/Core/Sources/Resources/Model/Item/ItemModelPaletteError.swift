import Foundation

/// An error thrown by ``ItemModelPalette``.
public enum ItemModelPaletteError: LocalizedError {
  case failedToLoadJSON(file: URL, Error)
}
