public struct InGameGUI {
  public init() {}

  public var body: GUIElement = GUIElement.stack {
    GUIElement.list(spacing: 2) {
      GUIElement.text("Hello, world!")

      GUIElement.clickable(.text("Press me")) {
        print("Button pressed")
      }
    }
      .centered()

    GUIElement.text("Top left")
      .positionInParent(0, 0)
  }
}
