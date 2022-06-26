import Foundation

/// A TrueType font.
public struct TrueTypeFontProvider: Decodable {
  public var file: String
  public var shift: [Float]
  public var size: Float
  public var oversample: Float
}
