import Foundation

/// A font provider.
public enum FontProvider: Decodable {
  case bitmap(BitmapFontProvider)
  case legacyUnicode(LegacyUnicodeFontProvider)
  case trueType(TrueTypeFontProvider)

  private enum CodingKeys: String, CodingKey {
    case type
  }

  /// A font provider type.
  public enum FontProviderType: String, Decodable {
    case bitmap
    case legacyUnicode = "legacy_unicode"
    case trueType = "ttf"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(FontProviderType.self, forKey: .type)

    switch type {
      case .bitmap:
        self = .bitmap(try BitmapFontProvider(from: decoder))
      case .legacyUnicode:
        self = .legacyUnicode(try LegacyUnicodeFontProvider(from: decoder))
      case .trueType:
        self = .trueType(try TrueTypeFontProvider(from: decoder))
    }
  }
}
