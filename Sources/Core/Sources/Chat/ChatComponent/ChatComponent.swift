/// A component of a chat message.
public struct ChatComponent: Decodable, Equatable {
  /// The component's style.
  var style: Style
  /// The component's content.
  var content: Content
  /// The component's children (displayed directly after ``content``).
  var children: [ChatComponent]

  private enum CodingKeys: String, CodingKey {
    case children = "extra"
    case text
    case translationIdentifier = "translate"
    case translationContent = "with"
    case score
    case keybind
  }

  /// Creates a new chat component.
  /// - Parameters:
  ///   - style: The component's style (inherited by children).
  ///   - content: The component's content.
  ///   - children: The component's children (dsplayed directly after ``content``).
  public init(style: Style, content: Content, children: [ChatComponent] = []) {
    self.style = style
    self.content = content
    self.children = children
  }

  public init(from decoder: Decoder) throws {
    let container: KeyedDecodingContainer<CodingKeys>
    do {
      container = try decoder.container(keyedBy: CodingKeys.self)
    } catch {
      let content = try decoder.singleValueContainer().decode(String.self)
      style = Style()
      self.content = Content.string(content)
      children = []
      return
    }
    style = try Style(from: decoder)

    if container.contains(.children) {
      children = try container.decode([ChatComponent].self, forKey: .children)
    } else {
      children = []
    }

    if container.contains(.text) {
      let string: String
      if let integer = try? container.decode(Int.self, forKey: .text) {
        string = String(integer)
      } else if let boolean = try? container.decode(Bool.self, forKey: .text) {
        string = String(boolean)
      } else {
        string = try container.decode(String.self, forKey: .text)
      }
      content = .string(string)
    } else if container.contains(.score) {
      let score = try container.decode(ScoreContent.self, forKey: .score)
      content = .score(score)
    } else if container.contains(.keybind) {
      let keybind = try container.decode(String.self, forKey: .keybind)
      content = .keybind(keybind)
    } else if container.contains(.translationIdentifier) {
      let identifier = try container.decode(String.self, forKey: .translationIdentifier)
      let translationContent: [ChatComponent]
      if container.contains(.translationContent) {
        translationContent = try container.decode([ChatComponent].self, forKey: .translationContent)
      } else {
        translationContent = []
      }
      content = .translation(LocalizedContent(translateKey: identifier, content: translationContent))
    } else {
      throw ChatComponentError.invalidChatComponentType
    }
  }

  /// Converts the chat component to plain text.
  /// - Parameter locale: The locale to use when resolving localized components.
  /// - Returns: The component's contents as plain text.
  func toText(with locale: MinecraftLocale) -> String {
    var output = content.toText(with: locale)
    for child in children {
      output += child.toText(with: locale)
    }

    // Remove legacy formatted text style codes
    let legacy = LegacyFormattedText(output)
    return legacy.toString()
  }
}
