public indirect enum GUIElement {
  case text(_ content: String, wrap: Bool = false)
  case clickable(_ element: GUIElement, action: () -> Void)
  case sprite(GUISprite)
  case customSprite(GUISpriteDescriptor)
  /// Stacks elements in the y direction. Aligns elements to the top left by default.
  case list(spacing: Int, elements: [GUIElement])
  /// Stacks elements in the z direction. Non-positioned elements default to the top-left corner.
  /// Elements appear on top of the elements that come before them.
  case stack(elements: [GUIElement])
  case positioned(element: GUIElement, constraints: Constraints)
  case sized(element: GUIElement, size: Vec2i)

  public static let textWrapIndent: Int = 4
  public static let lineSpacing: Int = 1

  public static func list(spacing: Int, @GUIBuilder elements: () -> [GUIElement]) -> GUIElement {
    .list(spacing: spacing, elements: elements())
  }

  public static func stack(@GUIBuilder elements: () -> [GUIElement]) -> GUIElement {
    .stack(elements: elements())
  }

  public func centered() -> GUIElement {
    .positioned(element: self, constraints: .center)
  }

  public func positionInParent(_ x: Int, _ y: Int) -> GUIElement {
    .positioned(element: self, constraints: .position(x, y))
  }

  public func sized(_ x: Int, _ y: Int) -> GUIElement {
    .sized(element: self, size: Vec2i(x, y))
  }

  public struct GUIRenderable {
    public var relativePosition: Vec2i
    public var size: Vec2i
    public var content: Content?
    public var children: [(GUIRenderable, GUIElement)]

    public enum Content {
      case text(wrappedLines: [String], hangingIndent: Int)
      case clickable(action: () -> Void)
      case sprite(GUISpriteDescriptor)
    }
  }

  public func resolveConstraints(
    availableSize: Vec2i,
    font: Font
  ) -> GUIRenderable {
    let relativePosition: Vec2i
    let size: Vec2i
    let content: GUIRenderable.Content?
    let children: [(GUIRenderable, GUIElement)]
    switch self {
      case let .text(text, wrap):
        // Wrap the lines, but if wrapping is disabled wrap to a width of Int.max (so that we can
        // still compute the width of the line).
        let lines = Self.wrap(
          text,
          maximumWidth: wrap ? availableSize.x : .max,
          indent: Self.textWrapIndent,
          font: font
        )
        relativePosition = .zero
        size = Vec2i(
          lines.map(\.width).max() ?? 0,
          lines.count * Font.defaultCharacterHeight + (lines.count - 1) * Self.lineSpacing
        )
        content = .text(
          wrappedLines: lines.map(\.line),
          hangingIndent: Self.textWrapIndent
        )
        children = []
      case let .clickable(label, action):
        let child = label.resolveConstraints(
          availableSize: availableSize,
          font: font
        )
        relativePosition = .zero
        size = child.size
        content = .clickable(action: action)
        children = [(child, label)]
      case let .sprite(sprite):
        let descriptor = sprite.descriptor
        relativePosition = .zero
        size = descriptor.size
        content = .sprite(descriptor)
        children = []
      case let .customSprite(descriptor):
        relativePosition = .zero
        size = descriptor.size
        content = .sprite(descriptor)
        children = []
      case let .list(spacing, elements):
        var availableSize = availableSize
        var childPosition = Vec2i(0, 0)
        children = elements.map { element in
          var renderable = element.resolveConstraints(
            availableSize: availableSize,
            font: font
          )
          renderable.relativePosition.y += childPosition.y

          let rowHeight = renderable.size.y + spacing
          childPosition.y += rowHeight
          availableSize.y -= rowHeight

          return (renderable, element)
        }
        relativePosition = .zero
        let width = children.map(\.0.size.x).max() ?? 0
        let height = elements.isEmpty ? 0 : childPosition.y - spacing
        size = Vec2i(width, height)
        content = nil
      case let .stack(elements):
        children = elements.map { element in
          let renderable = element.resolveConstraints(
            availableSize: availableSize,
            font: font
          )
          return (renderable, element)
        }
        size = Vec2i(
          children.map(\.0.size.x).max() ?? 0,
          children.map(\.0.size.y).max() ?? 0
        )
        relativePosition = .zero
        content = nil
      case let .positioned(element, constraints):
        let child = element.resolveConstraints(
          availableSize: availableSize,
          font: font
        )
        children = [(child, element)]
        relativePosition = constraints.solve(
          innerSize: child.size,
          outerSize: availableSize
        )
        size = child.size
        content = nil
      case let .sized(element, specifiedSize):
        let child = element.resolveConstraints(
          availableSize: specifiedSize,
          font: font
        )
        children = [(child, element)]
        relativePosition = .zero
        size = specifiedSize
        content = nil
    }

    return GUIRenderable(
      relativePosition: relativePosition,
      size: size,
      content: content,
      children: children
    )
  }

  /// `indent` must be less than `maximumWidth` and `maximumWidth` must greater than the width of
  /// each individual character in the string.
  static func wrap(_ text: String, maximumWidth: Int, indent: Int, font: Font) -> [(line: String, width: Int)] {
    assert(indent < maximumWidth, "indent must be smaller than maximumWidth")

    if text == "" {
      return [(line: "", width: 0)]
    }

    var wrapIndex: String.Index? = nil
    var latestSpace: String.Index? = nil
    var width = 0
    for i in text.indices {
      let character = text[i]
      guard let descriptor = Self.descriptor(for: character, from: font) else {
        continue
      }

      assert(
        descriptor.renderedWidth < maximumWidth,
        "maximumWidth must be greater than every individual character in the string"
      )

      // Compute the width with the current character included
      var nextWidth = width + descriptor.renderedWidth
      if i != text.startIndex {
        nextWidth += 1 // character spacing
      }

      // TODO: wrap on other characters such as '-' as well
      if character == " " {
        latestSpace = i
      }

      // Break before the current character if it'd bring the text over the maximum width
      if nextWidth > maximumWidth {
        if let spaceIndex = latestSpace {
          wrapIndex = spaceIndex
        } else {
          wrapIndex = i
        }
        break
      } else {
        width = nextWidth
      }
    }

    var lines: [(line: String, width: Int)] = []
    if let wrapIndex = wrapIndex {
      lines = [
        (line: String(text[text.startIndex..<wrapIndex]), width: width)
      ]

      var startIndex = wrapIndex
      while text[startIndex] == " " {
        startIndex = text.index(after: startIndex)
        if startIndex == text.endIndex {
          return lines // NOTE: early return
        }
      }
      let nonWrappedText = text[startIndex...]
      lines.append(contentsOf: wrap(
        String(nonWrappedText),
        maximumWidth: maximumWidth - indent,
        indent: 0,
        font: font
      ))
    } else {
      lines = [(line: text, width: width)]
    }

    return lines
  }

  static func descriptor(for character: Character, from font: Font) -> CharacterDescriptor? {
    if let descriptor = font.descriptor(for: character) {
      return descriptor
    } else if let descriptor = font.descriptor(for: "�") {
      return descriptor
    } else {
      log.warning("Failed to replace invalid character '\(character)' with placeholder '�'.")
      return nil
    }
  }
}
