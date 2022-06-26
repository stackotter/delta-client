import Metal
import simd

/// The uniforms for a GUI quad.
struct GUIQuadInstance {
  var position: SIMD2<Float>
  var size: SIMD2<Float>
  var uvMin: SIMD2<Float>
  var uvSize: SIMD2<Float>
  var textureIndex: UInt8

  init(
    position: SIMD2<Float>,
    size: SIMD2<Float>,
    uvMin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    textureIndex: UInt8
  ) {
    self.position = position
    self.size = size
    self.uvMin = uvMin
    self.uvSize = uvSize
    self.textureIndex = textureIndex
  }

  /// Creates a quad instance for the given character.
  init(for character: Character, with font: Font, fontArrayTexture: MTLTexture) throws {
    guard let descriptor = font.characters[character] else {
      throw GUIRendererError.invalidCharacter(character)
    }

    let arrayTextureWidth = Float(fontArrayTexture.width)
    let arrayTextureHeight = Float(fontArrayTexture.height)

    position = [
      0,
      Float(Font.defaultCharacterHeight - descriptor.height - descriptor.verticalOffset)
    ]
    size = [
      Float(descriptor.width),
      Float(descriptor.height)
    ]
    uvMin = [
      Float(descriptor.x) / arrayTextureWidth,
      Float(descriptor.y) / arrayTextureHeight
    ]
    uvSize = [
      Float(descriptor.width) / arrayTextureWidth,
      Float(descriptor.height) / arrayTextureHeight
    ]
    textureIndex = UInt8(descriptor.texture)
  }

  /// Translates the quad by the given amount.
  /// - Parameter amount: The amount of pixels to translate by along each axis.
  mutating func translate(amount: SIMD2<Float>) {
    self.position += amount
  }
}
