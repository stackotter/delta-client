extension LegacyFormattedText {
  /// A legacy text formatting code.
  ///
  /// [Reference](https://minecraft.fandom.com/wiki/Formatting_codes)
  public enum FormattingCode: RawRepresentable {
    case color(Color)
    case style(Style)

    public var rawValue: Character {
      switch self {
        case let .color(color):
          return color.rawValue
        case let .style(style):
          return style.rawValue
      }
    }
    
    public init?(rawValue: Character) {
      if let color = Color(rawValue: rawValue) {
        self = .color(color)
      } else if let style = Style(rawValue: rawValue) {
        self = .style(style)
      } else {
        return nil
      }
    }
  }
}
