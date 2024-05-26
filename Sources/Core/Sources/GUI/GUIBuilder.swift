@resultBuilder
public struct GUIBuilder {
  public static func buildBlock(_ elements: GUIElement...) -> GUIElement {
    .list(spacing: 0, elements: elements)
  }

  public static func buildEither(first component: GUIElement) -> GUIElement {
    component
  }

  public static func buildEither(second component: GUIElement) -> GUIElement {
    component
  }

  public static func buildOptional(_ component: GUIElement?) -> GUIElement {
    if let component = component {
      component
    } else {
      .spacer(width: 0, height: 0)
    }
  }
}
