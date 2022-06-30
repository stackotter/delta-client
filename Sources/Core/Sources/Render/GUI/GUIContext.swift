import Metal

struct GUIContext {
  var font: Font
  var fontArrayTexture: MTLTexture
  var guiTexturePalette: GUITexturePalette
  var guiArrayTexture: MTLTexture
  var itemTexturePalette: TexturePalette
  var itemArrayTexture: MTLTexture
}
