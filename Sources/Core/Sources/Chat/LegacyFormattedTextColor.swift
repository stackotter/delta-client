extension LegacyFormattedText {
  /// A legacy text color formatting code.
  public enum Color: Character {
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
}
