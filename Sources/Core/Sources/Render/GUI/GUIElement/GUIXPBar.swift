import simd

struct GUIXPBar: GUIElement {
  static let background = GUISprite.xpBarBackground
  static let foreground = GUISprite.xpBarForeground
  static let textColor: SIMD3<Float> = [126, 252, 31] / 255

  var level: Int
  var progress: Float

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var spriteMesh = GUIElementMesh(
      size: [
        Self.background.descriptor.size.x,
        Self.background.descriptor.size.y
      ],
      arrayTexture: context.guiArrayTexture,
      vertices: []
    )
    spriteMesh.position = [0, 6]

    func add(_ sprite: GUISpriteDescriptor, at position: SIMD2<Int>) {
      spriteMesh.vertices.append(contentsOf: GUIQuad(
        for: sprite,
        guiTexturePalette: context.guiTexturePalette,
        guiArrayTexture: context.guiArrayTexture,
        position: position
      ).toVertices())
    }

    var foreground = Self.foreground.descriptor
    foreground.size.x = Int(Float(foreground.size.x) * progress)

    add(Self.background.descriptor, at: [0, 0])
    add(foreground, at: [0, 0])

    var textMeshes: [GUIElementMesh] = []
    if level > 0 {
      textMeshes = try GUIColoredString(
        String(level),
        Self.textColor,
        outlineColor: .zero
      ).meshes(context: context)

      for (i, var mesh) in textMeshes.enumerated() {
        mesh.position = [(spriteMesh.size.x - mesh.size.x) / 2, 0]
        textMeshes[i] = mesh
      }
    }

    return [spriteMesh] + textMeshes
  }
}
