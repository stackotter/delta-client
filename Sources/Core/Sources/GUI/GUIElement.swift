// TODO: Update container related modifier methods to avoid unnecessary nesting where possible,
//   e.g. `.expand().padding(2)` should only result in a single container being added instead of
//   two levels of nested containers.
public indirect enum GUIElement {
  public enum Direction {
    case vertical
    case horizontal
  }

  public struct DirectionSet: ExpressibleByArrayLiteral, Equatable {
    public var horizontal: Bool
    public var vertical: Bool

    public static let both: Self = [.horizontal, .vertical]
    public static let neither: Self = []
    public static let horizontal: Self = [.horizontal]
    public static let vertical: Self = [.vertical]

    public init(arrayLiteral elements: Direction...) {
      vertical = elements.contains(.vertical)
      horizontal = elements.contains(.horizontal)
    }
  }

  public enum Edge {
    case top
    case bottom
    case left
    case right
  }

  public struct EdgeSet: ExpressibleByArrayLiteral {
    public var edges: Set<Edge>

    public static let top: Self = [.top]
    public static let bottom: Self = [.bottom]
    public static let left: Self = [.left]
    public static let right: Self = [.right]
    public static let vertical: Self = [.top, .bottom]
    public static let horizontal: Self = [.left, .right]
    public static let all: Self = [.top, .bottom, .left, .right]

    public init(arrayLiteral elements: Edge...) {
      edges = Set(elements)
    }

    public func contains(_ edge: Edge) -> Bool {
      edges.contains(edge)
    }
  }

  public struct Padding {
    public var top: Int
    public var bottom: Int
    public var left: Int
    public var right: Int

    /// The total padding along each axis.
    public var axisTotals: Vec2i {
      Vec2i(
        left + right,
        top + bottom
      )
    }

    public static let zero: Self = Padding(top: 0, bottom: 0, left: 0, right: 0)

    public init(top: Int, bottom: Int, left: Int, right: Int) {
      self.top = top
      self.bottom = bottom
      self.left = left
      self.right = right
    }

    public init(edges: EdgeSet, amount: Int) {
      self.top = edges.contains(.top) ? amount : 0
      self.bottom = edges.contains(.bottom) ? amount : 0
      self.left = edges.contains(.left) ? amount : 0
      self.right = edges.contains(.right) ? amount : 0
    }
  }

  case text(_ content: String, wrap: Bool = false, color: Vec4f = Vec4f(1, 1, 1, 1))
  case message(_ message: ChatComponent, wrap: Bool = true)
  case interactable(_ element: GUIElement, handleInteraction: (Interaction) -> Bool)
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
  case container(
    element: GUIElement,
    background: Vec4f?,
    padding: Padding,
    paddingColor: Vec4f?,
    expandDirections: DirectionSet = .neither
  )
  case floating(element: GUIElement)
  case item(id: Int)

  public var children: [GUIElement] {
    switch self {
      case let .list(_, _, elements), let .stack(elements):
        return elements
      case let .interactable(element, _), let .positioned(element, _),
          let .sized(element, _, _), let .container(element, _, _, _, _),
          let .floating(element):
        return [element]
      case .text, .message, .sprite, .customSprite, .spacer, .item:
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

  public func positionInParent(_ position: Vec2i) -> GUIElement {
    .positioned(element: self, constraints: .position(position.x, position.y))
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

  public func size(_ size: Vec2i) -> GUIElement {
    .sized(element: self, width: size.x, height: size.y)
  }

  public func padding(_ amount: Int) -> GUIElement {
    self.padding(.all, amount)
  }

  public func padding(_ edges: EdgeSet, _ amount: Int) -> GUIElement {
    .container(element: self, background: nil, padding: Padding(edges: edges, amount: amount), paddingColor: nil)
  }

  public func border(_ amount: Int, _ color: Vec4f) -> GUIElement {
    self.border(.all, amount, color)
  }

  public func border(_ edges: EdgeSet, _ amount: Int, _ color: Vec4f) -> GUIElement {
    .container(element: self, background: nil, padding: Padding(edges: edges, amount: amount), paddingColor: color)
  }

  public func background(_ color: Vec4f) -> GUIElement {
    // Sometimes we can just update the element instead of adding another layer.
    switch self {
      case let .container(element, background, padding, paddingColor, expandDirections):
        if background == nil {
          return .container(
            element: element,
            background: color,
            padding: padding,
            paddingColor: paddingColor,
            expandDirections: expandDirections
          )
        }
      default:
        break
    }
    return .container(element: self, background: color, padding: .zero, paddingColor: nil)
  }

  public func expand(_ directions: DirectionSet = .both) -> GUIElement {
    if case let .container(element, background, padding, paddingColor, .neither) = self {
      return .container(
        element: element,
        background: background,
        padding: padding,
        paddingColor: paddingColor,
        expandDirections: directions
      )
    }
    return .container(element: self, background: .zero, padding: .zero, paddingColor: nil, expandDirections: directions)
  }

  public func onClick(_ action: @escaping () -> Void) -> GUIElement {
    onHoverKeyPress(matching: .leftMouseButton, action)
  }

  public func onRightClick(_ action: @escaping () -> Void) -> GUIElement {
    onHoverKeyPress(matching: .rightMouseButton, action)
  }

  public func onHoverKeyPress(matching key: Key, _ action: @escaping () -> Void) -> GUIElement {
    .interactable(
      self,
      handleInteraction: { interaction in
        switch interaction {
          case let .press(event):
            if event.key == key {
              action()
              return true
            } else {
              return false
            }
          case .release:
            return false
        }
      }
    )
  }

  public func onHoverKeyPress(_ action: @escaping (KeyPressEvent) -> Bool) -> GUIElement {
    .interactable(
      self,
      handleInteraction: { interaction in
        switch interaction {
          case let .press(event):
            return action(event)
          case .release:
            return false
        }
      }
    )
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

  public enum Interaction {
    case press(KeyPressEvent)
    case release(KeyReleaseEvent)
  }

  public struct GUIRenderable {
    public var relativePosition: Vec2i
    public var size: Vec2i
    public var content: Content?
    public var children: [GUIRenderable]

    public enum Content {
      case text(wrappedLines: [String], hangingIndent: Int, color: Vec4f)
      case interactable(handleInteraction: (Interaction) -> Bool)
      case sprite(GUISpriteDescriptor)
      /// Fills the renderable with the given background color. Goes behind
      /// any children that the renderable may have.
      case background(Vec4f)
      case item(id: Int)
    }

    // Returns true if the click was handled by the renderable or any of its children.
    public func handleInteraction(_ interaction: Interaction, at position: Vec2i) -> Bool {
      guard Self.isHit(position, inBoxAt: relativePosition, ofSize: size) else {
        return false
      }

      switch content {
        case let .interactable(handleInteraction):
          if handleInteraction(interaction) {
            return true
          }
        case .text, .sprite, .background, .item, nil:
          break
      }

      let relativeClickPosition = position &- relativePosition
      for renderable in children.reversed() {
        if renderable.handleInteraction(interaction, at: relativeClickPosition) {
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
    font: Font,
    locale: MinecraftLocale
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
      case let .message(message, wrap):
        let text = message.toText(with: locale)
        return GUIElement.text(text, wrap: wrap)
          .resolveConstraints(availableSize: availableSize, font: font, locale: locale)
      case let .interactable(label, handleInteraction):
        let child = label.resolveConstraints(
          availableSize: availableSize,
          font: font,
          locale: locale
        )
        relativePosition = .zero
        size = child.size
        content = .interactable(handleInteraction: handleInteraction)
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
            font: font,
            locale: locale
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
            font: font,
            locale: locale
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
          font: font,
          locale: locale
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
          font: font,
          locale: locale
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
      case let .container(element, background, padding, paddingColor, expandDirections):
        let paddingAxisTotals = padding.axisTotals
        var child = element.resolveConstraints(
          availableSize: availableSize &- paddingAxisTotals,
          font: font,
          locale: locale
        )
        child.relativePosition &+= Vec2i(padding.left, padding.top)
        relativePosition = .zero
        size = Vec2i(
          expandDirections.horizontal
            ? availableSize.x
            : min(availableSize.x, child.size.x + paddingAxisTotals.x),
          expandDirections.vertical
            ? availableSize.y
            : min(availableSize.y, child.size.y + paddingAxisTotals.y)
        )

        let expandedChildSize = size &- paddingAxisTotals

        if let paddingColor = paddingColor {
          // Something feels kinda dark about this variable name...
          var borderChildren: [GUIRenderable] = []

          // https://open.spotify.com/track/5hM5arv9KDbCHS0k9uqwjr?si=58df9b2231e848b8
          func addBorderLine(position: Vec2i, size: Vec2i) {
            borderChildren.append(GUIRenderable(
              relativePosition: position,
              size: size,
              content: .background(paddingColor),
              children: []
            ))
          }

          if padding.left != 0 {
            addBorderLine(
              position: [0, 0],
              size: [padding.left, expandedChildSize.y + paddingAxisTotals.y]
            )
          }
          if padding.right != 0 {
            addBorderLine(
              position: [padding.left + expandedChildSize.x, 0],
              size: [padding.right, expandedChildSize.y + paddingAxisTotals.y]
            )
          }
          if padding.top != 0 {
            addBorderLine(
              position: [padding.left, 0],
              size: [expandedChildSize.x, padding.top]
            )
          }
          if padding.bottom != 0 {
            addBorderLine(
              position: [padding.left, padding.top + expandedChildSize.y],
              size: [expandedChildSize.x, padding.bottom]
            )
          }

          let backgroundChild: GUIRenderable?
          if let background = background {
            backgroundChild = GUIRenderable(
              relativePosition: Vec2i(padding.left, padding.top),
              size: child.size,
              content: .background(background),
              children: []
            )
          } else {
            backgroundChild = nil
          }

          children = borderChildren + [
            backgroundChild,
            child
          ].compactMap(identity)
          content = nil
        } else {
          children = [child]
          content = background.map(GUIRenderable.Content.background)
        }
      case let .floating(element):
        let child = element.resolveConstraints(
          availableSize: availableSize,
          font: font,
          locale: locale
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
