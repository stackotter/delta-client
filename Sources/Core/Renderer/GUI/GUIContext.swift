import Metal
import DeltaCore

struct GUIContext {
  var font: Font
  var fontArrayTexture: MTLTexture
  var guiTexturePalette: GUITexturePalette
  var guiArrayTexture: MTLTexture
  var itemTexturePalette: TexturePalette
  var itemArrayTexture: MTLTexture
  var itemModelPalette: ItemModelPalette
  var blockArrayTexture: MTLTexture
  var blockModelPalette: BlockModelPalette
  var blockTexturePalette: TexturePalette
}
