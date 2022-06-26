import Foundation

/// A bitmap font atlas backed by a png file.
public struct BitmapFontProvider: Decodable {
  /// PNG file containing font atlas.
  public var file: Identifier
  /// Vertical shift of characters in atlas.
  public var verticalShift: Int
  /// Characters in atlas.
  public var characters: [String]

  private enum CodingKeys: String, CodingKey {
    case file
    case verticalShift = "ascent"
    case characters = "chars"
  }
}
