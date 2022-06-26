import Foundation

/// A palette containing any number of fonts.
public struct FontPalette {
  /// The palette's fonts, keyed by name.
  public var fonts: [String: Font] {
    didSet {
      defaultFont = fonts["default"] ?? Font()
    }
  }

  /// The palette's default font.
  public private(set) var defaultFont: Font

  /// Creates a new font palette.
  /// - Parameter fonts: The palette's fonts.
  public init(_ fonts: [String: Font] = [:]) {
    self.fonts = fonts
    defaultFont = fonts["default"] ?? Font()
  }

  /// Load a font palette from a resource pack.
  /// - Parameters:
  ///   - manifestDirectory: The directory containing font manifests.
  ///   - textureDirectory: The directory containing the namespace's resources.
  /// - Returns: A font palette.
  public static func load(from manifestDirectory: URL, textureDirectory: URL) throws -> FontPalette {
    let contents = try FileManager.default.contentsOfDirectory(at: manifestDirectory, includingPropertiesForKeys: nil)
    var fonts: [String: Font] = [:]
    for file in contents where file.pathExtension == "json" {
      let name = file.deletingPathExtension().lastPathComponent
      let font = try Font.load(from: file, textureDirectory: textureDirectory)
      fonts[name] = font
    }
    return FontPalette(fonts)
  }

  /// Gets the font with the given name.
  /// - Parameter name: The name of the font to get.
  /// - Returns: The requested font if it exists.
  public func font(named name: String) -> Font? {
    return fonts[name]
  }
}
