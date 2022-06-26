extension GUIElement {
  enum Content: ExpressibleByStringLiteral {
    case text(String)

    init(stringLiteral value: StringLiteralType) {
      self = .text(value)
    }
  }
}
