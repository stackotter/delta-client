import FirebladeMath

struct GUIXPBar: GUIElement {
  static let background = GUISprite.xpBarBackground
  static let foreground = GUISprite.xpBarForeground
  static let textColor: Vec4f = [126, 252, 31, 255] / 255

  var level: Int
  var progress: Float

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var spriteMesh = GUIElementMesh(
      size: [
        Self.background.descriptor.size.x,
        Self.background.descriptor.size.y
      ],
      arrayTexture: context.guiArrayTexture,
      vertices: .empty
    )
    spriteMesh.position = [0, 6]

    func add(_ sprite: GUISpriteDescriptor, at position: Vec2i) {
      spriteMesh.vertices.append(contentsOf: .tuples([GUIQuad(
        for: sprite,
        guiTexturePalette: context.guiTexturePalette,
        guiArrayTexture: context.guiArrayTexture,
        position: position
      ).toVertexTuple()]))
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
        outlineColor: [0, 0, 0, 1]
      ).meshes(context: context)

      for (i, var mesh) in textMeshes.enumerated() {
        mesh.position = [(spriteMesh.size.x - mesh.size.x) / 2, 0]
        textMeshes[i] = mesh
      }
    }

    return [spriteMesh] + textMeshes
  }
}
