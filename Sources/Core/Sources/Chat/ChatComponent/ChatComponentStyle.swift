import Foundation

extension ChatComponent {
  public struct Style: Decodable, Equatable {
    /// If `true`, the text is **bold**.
    public var bold: Bool?
    /// If `true`, the text is *italic*.
    public var italic: Bool?
    /// If `true`, the text has an underline.
    public var underlined: Bool?
    /// If `true`, the text has a ~~line through the middle~~.
    public var strikethrough: Bool?
    /// If `true`, each character of the text cycles through characters of the same width to hide the message.
    public var obfuscated: Bool?
    /// The color of text.
    public var color: Color?

    private enum CodingKeys: String, CodingKey {
      case bold
      case italic
      case underlined
      case strikethrough
      case obfuscated
      case color
    }

    /// Creates a chat style. Defaults to white text with no decoration.
    public init(
      bold: Bool? = nil,
      italic: Bool? = nil,
      underlined: Bool? = nil,
      strikethrough: Bool? = nil,
      obfuscated: Bool? = nil,
      color: Color? = nil
    ) {
      self.bold = bold
      self.italic = italic
      self.underlined = underlined
      self.strikethrough = strikethrough
      self.obfuscated = obfuscated
      self.color = color
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      bold = (try? container.decode(Bool.self, forKey: .bold))
      italic = (try? container.decode(Bool.self, forKey: .italic))
      underlined = (try? container.decode(Bool.self, forKey: .underlined))
      strikethrough = (try? container.decode(Bool.self, forKey: .strikethrough))
      obfuscated = (try? container.decode(Bool.self, forKey: .obfuscated))
      color = (try? container.decode(Color.self, forKey: .color))
    }
  }
}
