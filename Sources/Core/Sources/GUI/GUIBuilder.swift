@resultBuilder
public struct GUIBuilder {
  public static func buildBlock(_ elements: GUIElement...) -> [GUIElement] {
    elements
  }

  public static func buildEither(first component: [GUIElement]) -> GUIElement {
    .stack(elements: component)
  }

  public static func buildEither(second component: [GUIElement]) -> GUIElement {
    .stack(elements: component)
  }

  public static func buildOptional(_ component: [GUIElement]?) -> GUIElement {
    if let component = component {
      .stack(elements: component)
    } else {
      .spacer(width: 0, height: 0)
    }
  }
}
