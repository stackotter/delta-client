import Metal
import simd

/// A convenient way to construct the vertices for a GUI quad.
struct GUIQuad {
  static var vertexPositions: [SIMD2<Float>] = [
    [0, 0],
    [1, 0],
    [1, 1],
    [0, 1]
  ]

  static var uvs: [SIMD2<Float>] = [
    [0, 0],
    [1, 0],
    [1, 1],
    [0, 1]
  ]

  var position: SIMD2<Float>
  var size: SIMD2<Float>
  var uvMin: SIMD2<Float>
  var uvSize: SIMD2<Float>
  var textureIndex: UInt16
  var tint: SIMD4<Float>

  init(
    position: SIMD2<Float>,
    size: SIMD2<Float>,
    uvMin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    textureIndex: UInt16,
    tint: SIMD4<Float> = [1, 1, 1, 1]
  ) {
    self.position = position
    self.size = size
    self.uvMin = uvMin
    self.uvSize = uvSize
    self.textureIndex = textureIndex
    self.tint = tint
  }

  /// Creates a quad instance for a solid color rectangle.
  init(
    position: SIMD2<Float>,
    size: SIMD2<Float>,
    color: SIMD4<Float>
  ) {
    self.position = position
    self.size = size
    self.tint = color
    self.uvMin = .zero
    self.uvSize = .zero
    self.textureIndex = UInt16.max
  }

  /// Creates a quad instance for the given sprite.
  init(
    for sprite: GUISpriteDescriptor,
    guiTexturePalette: GUITexturePalette,
    guiArrayTexture: MTLTexture,
    position: SIMD2<Int> = .zero
  ) {
    let textureSize: SIMD2<Float> = [
      Float(guiArrayTexture.width),
      Float(guiArrayTexture.height)
    ]

    self.position = SIMD2<Float>(position)
    size = SIMD2<Float>(sprite.size)
    uvMin = SIMD2<Float>(sprite.position) / textureSize
    uvSize = self.size / textureSize
    textureIndex = UInt16(guiTexturePalette.textureIndex(for: sprite.slice))
    tint = [1, 1, 1, 1]
  }

  func toVertices() -> [GUIVertex] {
    var vertices: [GUIVertex] = []
    vertices.reserveCapacity(4)
    for (position, uv) in zip(Self.vertexPositions, Self.uvs) {
      vertices.append(GUIVertex(
        position: position * size + self.position,
        uv: uv * uvSize + uvMin,
        tint: tint,
        textureIndex: textureIndex
      ))
    }
    return vertices
  }

  /// Translates the quad by the given amount.
  /// - Parameter amount: The amount of pixels to translate by along each axis.
  mutating func translate(amount: SIMD2<Float>) {
    self.position += amount
  }
}
