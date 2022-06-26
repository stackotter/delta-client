import Foundation

/// A font's manifest file containing providers for rendering the font.
public struct FontManifest: Decodable {
  /// Providers for rendering the font.
  public var providers: [FontProvider] = []

  /// Loads a font manifest.
  /// - Parameter file: The font manifest file.
  public static func load(from file: URL) throws -> FontManifest {
    let data = try Data(contentsOf: file)
    return try JSONDecoder().decode(FontManifest.self, from: data)
  }
}
