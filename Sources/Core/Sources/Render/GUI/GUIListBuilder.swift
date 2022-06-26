struct GUIListBuilder {
  var elements: [GUIElement]
  var x: Int
  var y: Int
  var currentY: Int
  var spacing: Int

  init(x: Int = 0, y: Int = 0, spacing: Int) {
    elements = []
    self.x = x
    self.y = y
    currentY = y
    self.spacing = spacing
  }

  mutating func add(_ text: String) {
    elements.append(GUIElement(.text(text), .position(x, currentY)))
    currentY += Font.defaultCharacterHeight + spacing
  }

  mutating func add(spacer height: Int) {
    currentY += height
  }
}
