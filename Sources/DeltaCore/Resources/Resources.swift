import Foundation

extension ResourcePack {
  public struct Resources {
    public var blockTexturePalette = TexturePalette()
    public var blockModelPalette = BlockModelPalette()
    public var locales: [String: MinecraftLocale] = [:]
  }
}
