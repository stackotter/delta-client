extension LegacyTextFormatter {
  /// A legacy text formatting code.
  ///
  /// [Reference](https://minecraft.fandom.com/wiki/Formatting_codes)
  public enum FormattingCode: RawRepresentable {
    case color(ColorCode)
    case style(StyleCode)
    
    /// A legacy text style formatting code.
    public enum StyleCode: Character {
      case bold = "l"
      case strikethrough = "m"
      case underline = "n"
      case italic = "o"
      case reset = "r"
    }
    
    /// A legacy text color formatting code.
    public enum ColorCode: Character {
      case black = "0"
      case darkBlue = "1"
      case darkGreen = "2"
      case darkAqua = "3"
      case darkRed = "4"
      case darkPurple = "5"
      case gold = "6"
      case gray = "7"
      case darkGray = "8"
      case blue = "9"
      case green = "a"
      case aqua = "b"
      case red = "c"
      case lightPurple = "d"
      case yellow = "e"
      case white = "f"
      
      /// The hex value of the color.
      public var hex: String {
        switch self {
          case .black: return "#000000"
          case .darkBlue: return "#0000AA"
          case .darkGreen: return "#00AA00"
          case .darkAqua: return "#00AAAA"
          case .darkRed: return "#AA0000"
          case .darkPurple: return "#AA00AA"
          case .gold: return "#FFAA00"
          case .gray: return "#AAAAAA"
          case .darkGray: return "#555555"
          case .blue: return "#5555FF"
          case .green: return "#55FF55"
          case .aqua: return "#55FFFF"
          case .red: return "#FF5555"
          case .lightPurple: return "#FF55FF"
          case .yellow: return "#FFFF55"
          case .white: return "#FFFFFF"
        }
      }
    }
    
    public var rawValue: Character {
      switch self {
        case let .color(color):
          return color.rawValue
        case let .style(style):
          return style.rawValue
      }
    }
    
    public init?(rawValue: Character) {
      if let color = ColorCode(rawValue: rawValue) {
        self = .color(color)
      } else if let style = StyleCode(rawValue: rawValue) {
        self = .style(style)
      } else {
        return nil
      }
    }
  }
}
