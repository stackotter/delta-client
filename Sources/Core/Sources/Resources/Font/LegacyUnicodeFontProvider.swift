import Foundation

/// A legacy unicode font.
public struct LegacyUnicodeFontProvider: Decodable {
  public var sizes: Identifier
  public var template: String
}
