public indirect enum GUIElement {
  public enum Direction {
    case vertical
    case horizontal
  }

  case text(_ content: String, wrap: Bool = false, color: Vec4f = Vec4f(1, 1, 1, 1))
  case clickable(_ element: GUIElement, action: () -> Void)
  case sprite(GUISprite)
  case customSprite(GUISpriteDescriptor)
  /// Stacks elements in the specified direction. Aligns elements to the top left by default.
  case list(direction: Direction = .vertical, spacing: Int, elements: [GUIElement])
  /// Stacks elements in the z direction. Non-positioned elements default to the top-left corner.
  /// Elements appear on top of the elements that come before them.
  case stack(elements: [GUIElement])
  case positioned(element: GUIElement, constraints: Constraints)
  case sized(element: GUIElement, width: Int?, height: Int?)
  case spacer(width: Int, height: Int)
  /// Wraps an element with a background.
  case container(background: Vec4f, padding: Int, element: GUIElement)
  case floating(element: GUIElement)
  case item(id: Int)

  public var children: [GUIElement] {
    switch self {
      case let .list(_, _, elements), let .stack(elements):
        return elements
      case let .clickable(element, _), let .positioned(element, _), let .sized(element, _, _), let .container(_, _, element), let .floating(element):
        return [element]
      case .text, .sprite, .customSprite, .spacer, .item:
        return []
    }
  }

  public static let textWrapIndent: Int = 4
  public static let lineSpacing: Int = 1

  public static func list(
    direction: Direction = .vertical,
    spacing: Int,
    @GUIBuilder elements: () -> GUIElement
  ) -> GUIElement {
    .list(direction: direction, spacing: spacing, elements: elements().children)
  }

  public static func forEach<S: Sequence>(
    in values: S,
    direction: Direction = .vertical,
    spacing: Int,
    @GUIBuilder element: (S.Element) -> GUIElement
  ) -> GUIElement {
    let elements = values.map(element)
    return .list(direction: direction, spacing: spacing, elements: elements)
  }

  public static func stack(@GUIBuilder elements: () -> GUIElement) -> GUIElement {
    .stack(elements: elements().children)
  }

  public func center() -> GUIElement {
    .positioned(element: self, constraints: .center)
  }

  public func positionInParent(_ x: Int, _ y: Int) -> GUIElement {
    .positioned(element: self, constraints: .position(x, y))
  }

  public func constraints(
    _ verticalConstraint: VerticalConstraint,
    _ horizontalConstraint: HorizontalConstraint
  ) -> GUIElement {
    .positioned(element: self, constraints: Constraints(verticalConstraint, horizontalConstraint))
  }

  public func constraints(_ constraints: Constraints) -> GUIElement {
    .positioned(element: self, constraints: constraints)
  }

  /// `nil` indicates to use the natural width/height (the default).
  public func size(_ width: Int?, _ height: Int?) -> GUIElement {
    .sized(element: self, width: width, height: height)
  }

  public func padding(_ padding: Int) -> GUIElement {
    .container(background: .zero, padding: padding, element: self)
  }

  public func background(_ color: Vec4f) -> GUIElement {
    // Sometimes we can just update the element instead of adding another layer.
    switch self {
      case let .container(background, padding, element):
        if background == .zero {
          return .container(background: color, padding: padding, element: element)
        }
      default:
        break
    }
    return .container(background: color, padding: 0, element: self)
  }

  public func onClick(_ action: @escaping () -> Void) -> GUIElement {
    .clickable(self, action: action)
  }

  /// Sets an element's apparent size to zero so that it doesn't partake in layout.
  /// It will still get put exactly where it otherwise would, but for example if the
  /// element is in a list, all following elements will be positioned as if the element
  /// doesn't exist (except double spacing where the element would've been).
  ///
  /// Any constraints placed on an element after it has been floated will act as if the
  /// element is of zero size. This probably isn't the best and could be fixed without
  /// too much effort (by making element rendering logic understand floating instead of
  /// just pretending the size is zero).
  public func float() -> GUIElement {
    .floating(element: self)
  }

  public struct GUIRenderable {
    public var relativePosition: Vec2i
    public var size: Vec2i
    public var content: Content?
    public var children: [GUIRenderable]

    public enum Content {
      case text(wrappedLines: [String], hangingIndent: Int, color: Vec4f)
      case clickable(action: () -> Void)
      case sprite(GUISpriteDescriptor)
      /// Fills the renderable with the given background color. Goes behind
      /// any children that the renderable may have.
      case background(Vec4f)
      case item(id: Int)
    }

    // Returns true if the click was handled by the renderable or any of its children.
    public func handleClick(at position: Vec2i) -> Bool {
      guard Self.isHit(position, inBoxAt: relativePosition, ofSize: size) else {
        return false
      }

      switch content {
        case let .clickable(action):
          action()
          return true
        case .text, .sprite, .background, .item, nil:
          break
      }

      let relativeClickPosition = position &- relativePosition
      for renderable in children.reversed() {
        if renderable.handleClick(at: relativeClickPosition) {
          return true
        }
      }

      return false
    }

    private static func isHit(
      _ position: Vec2i,
      inBoxAt upperLeft: Vec2i,
      ofSize size: Vec2i
    ) -> Bool {
      return
        position.x > upperLeft.x && position.x < (upperLeft.x + size.x)
        && position.y > upperLeft.y && position.y < (upperLeft.y + size.y)
    }
  }

  public func resolveConstraints(
    availableSize: Vec2i,
    font: Font
  ) -> GUIRenderable {
    let relativePosition: Vec2i
    let size: Vec2i
    let content: GUIRenderable.Content?
    let children: [GUIRenderable]
    switch self {
      case let .text(text, wrap, color):
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
          hangingIndent: Self.textWrapIndent,
          color: color
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
        children = [child]
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
      case let .list(direction, spacing, elements):
        var availableSize = availableSize
        var childPosition = Vec2i(0, 0)
        let axisComponent = direction == .vertical ? 1 : 0
        children = elements.map { element in
          var renderable = element.resolveConstraints(
            availableSize: availableSize,
            font: font
          )
          renderable.relativePosition[axisComponent] += childPosition[axisComponent]

          let rowSize = renderable.size[axisComponent] + spacing
          childPosition[axisComponent] += rowSize
          availableSize[axisComponent] -= rowSize

          return renderable
        }
        relativePosition = .zero
        let lengthAlongAxis = elements.isEmpty ? 0 : childPosition[axisComponent] - spacing
        switch direction {
          case .vertical:
            let width = children.map(\.size.x).max() ?? 0
            size = Vec2i(width, lengthAlongAxis)
          case .horizontal:
            let height = children.map(\.size.y).max() ?? 0
            size = Vec2i(lengthAlongAxis, height)
        }
        content = nil
      case let .stack(elements):
        children = elements.map { element in
          element.resolveConstraints(
            availableSize: availableSize,
            font: font
          )
        }
        size = Vec2i(
          children.map { renderable in
            renderable.size.x + renderable.relativePosition.x
          }.max() ?? 0,
          children.map { renderable in
            renderable.size.y + renderable.relativePosition.y
          }.max() ?? 0
        )
        relativePosition = .zero
        content = nil
      case let .positioned(element, constraints):
        let child = element.resolveConstraints(
          availableSize: availableSize,
          font: font
        )
        children = [child]
        relativePosition = constraints.solve(
          innerSize: child.size,
          outerSize: availableSize
        )
        size = child.size
        content = nil
      case let .sized(element, width, height):
        let child = element.resolveConstraints(
          availableSize: Vec2i(
            width ?? availableSize.x,
            height ?? availableSize.y
          ),
          font: font
        )
        children = [child]
        relativePosition = .zero
        size = Vec2i(
          width ?? child.size.x,
          height ?? child.size.y
        )
        content = nil
      case let .spacer(width, height):
        children = []
        relativePosition = .zero
        size = Vec2i(width, height)
        content = nil
      case let .container(background, padding, element):
        var child = element.resolveConstraints(
          availableSize: availableSize &- Vec2i(repeating: padding * 2),
          font: font
        )
        child.relativePosition &+= Vec2i(repeating: padding)
        children = [child]
        relativePosition = .zero
        size = Vec2i(
          min(availableSize.x, child.size.x + padding * 2),
          min(availableSize.y, child.size.y + padding * 2)
        )

        if background.w != 0 {
          content = .background(background)
        } else {
          content = nil
        }
      case let .floating(element):
        let child = element.resolveConstraints(
          availableSize: availableSize,
          font: font
        )
        children = [child]
        relativePosition = .zero
        size = .zero
        content = nil
      case let .item(id):
        children = []
        relativePosition = .zero
        size = Vec2i(16, 16)
        content = .item(id: id)
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

      // Break before the current character if it'd bring the text over the maximum width.
      // If it's the first character, never wrap because otherwise we enter an infinite loop.
      if nextWidth > maximumWidth && i != text.startIndex {
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
