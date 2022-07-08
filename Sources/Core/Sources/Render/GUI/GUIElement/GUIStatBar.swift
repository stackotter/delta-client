/// An icon-based stat bar such as the health bar or hunger bar.
struct GUIStatBar: GUIElement {
  /// Stat value out of 20 (1 unit is a half icon).
  var value: Int
  /// The full icon (e.g. full heart).
  var fullIcon: GUISprite
  /// The half icon (e.g. half heart).
  var halfIcon: GUISprite
  /// The outline icon (displayed behind each spot an icon could go).
  var outlineIcon: GUISprite
  /// Constructor for horizontal constraint.
  var reversed = false

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    var mesh = GUIElementMesh(size: [81, 9], arrayTexture: context.guiArrayTexture)

    func add(_ sprite: GUISprite, at x: Int) {
      mesh.quads.append(GUIQuadInstance(
        for: sprite.descriptor,
        guiTexturePalette: context.guiTexturePalette,
        guiArrayTexture: context.guiArrayTexture,
        position: [x, 0]
      ))
    }

    let fullIconCount = value / 2
    let hasHalfIcon = value % 2 == 1
    for i in 0..<10 {
      // Position
      var x = i * 8
      if reversed {
        x = mesh.size.x - x - outlineIcon.descriptor.size.x
      }

      // Outline
      add(outlineIcon, at: x)

      // Full and half icons
      if i < fullIconCount {
        add(fullIcon, at: x)
      } else if hasHalfIcon && i == fullIconCount {
        add(halfIcon, at: x)
      }
    }

    return [mesh]
  }
}
