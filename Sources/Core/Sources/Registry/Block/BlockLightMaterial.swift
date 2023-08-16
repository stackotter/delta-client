import Foundation

extension Block {
  /// A block's material properties that are relevant to light.
  public struct LightMaterial: Codable {
    /// Is the block translucent.
    public var isTranslucent: Bool
    /// How much light the block blocks from 0 to 15. 0 blocks no light and 15 blocks all light.
    public var opacity: Int
    /// How much light the block emits from 0 to 15. 0 emits no light and 15 emits the maximum possible block light level (15).
    public var luminance: Int
    /// Whether the block is only transparent under some conditions. E.g. slabs have conditional
    /// transparency (light only passes through in certain directions).
    public var isConditionallyTransparent: Bool

    /// Whether this material is opaque.
    public var isOpaque: Bool {
      return opacity == 15
    }

    public init(
      isTranslucent: Bool,
      opacity: Int,
      luminance: Int,
      isConditionallyTransparent: Bool
    ) {
      self.isTranslucent = isTranslucent
      self.opacity = opacity
      self.luminance = luminance
      self.isConditionallyTransparent = isConditionallyTransparent
    }

    /// Used for missing blocks.
    public static var `default` = LightMaterial(
      isTranslucent: false,
      opacity: 0,
      luminance: 0,
      isConditionallyTransparent: false)
  }
}
