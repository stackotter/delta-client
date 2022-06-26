import Foundation

// TODO: move resource loading code to here

extension ResourcePack {
  /// A namespace of resources.
  public struct Resources {
    /// The palette holding block textures.
    public var blockTexturePalette = TexturePalette()
    /// The palette holding block models.
    public var blockModelPalette = BlockModelPalette()
    /// The locales.
    public var locales: [String: MinecraftLocale] = [:]
    /// The colors of biomes.
    public var biomeColors = BiomeColors()
    /// The fonts.
    public var fontPalette = FontPalette()

    /// Creates a new empty namespace of resources.
    public init() {}
  }
}
