extension GUIElement {
  /// The renderable content of a GUI element.
  enum Content: ExpressibleByStringLiteral {
    case text(String)
    case sprite(GUISprite)
    case customSprite(GUISpriteDescriptor)

    init(stringLiteral value: StringLiteralType) {
      self = .text(value)
    }
  }
}
