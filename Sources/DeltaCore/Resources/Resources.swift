import Foundation

// TODO: move resource loading code to here

extension ResourcePack {
  public struct Resources {
    public var blockTexturePalette = TexturePalette()
    public var blockModelPalette = BlockModelPalette()
    public var locales: [String: MinecraftLocale] = [:]
    public var biomeColors = BiomeColors()
  }
}
