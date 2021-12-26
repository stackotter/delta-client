import Foundation
import AppKit


// MARK: - MCAttributedString


/// Parses minecraft-formatted color coded strings into their attributed counterpart
class MCAttributedString {
  
  // MARK: - FormattingCode
  
  
  /// Legacy color codes
  ///
  /// [Reference](https://minecraft.fandom.com/wiki/Formatting_codes)
  private enum ColorFormattingCodes: Character {
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
    case minecoinGold = "g"
    
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
        case .minecoinGold: return "#DDD605"
      }
    }
  }
  
  
  // MARK: - Datasource properties
  
  
  /// Special character that precedes legacy color codes
  private let legacyDelimiter: Character = "§"
  /// Source text
  private let string: String
  /// The color coded string
  private(set) var attributed = NSMutableAttributedString(string: "")
  
  
  // MARK: - Inits
  
  
  /// Class init
  ///
  /// - Parameter string: the unstyled, plaintext string
  init(string: String) {
    self.string = string
    styleLegacy()
  }
  
  
  // MARK: - Private methods
  
  
  /// Sets attributes for legacy preset
  private func styleLegacy() {
    // Gathering text attributes
    let tokenized = string.split(separator: legacyDelimiter)
    var attributedElements: [(attribute: ColorFormattingCodes, string: String)] = []
    for token in tokenized {
      var s = token
      guard let kColorCode = s.first, let colorCode = ColorFormattingCodes(rawValue: kColorCode) else {
        attributedElements.append((attribute: .white, string: String(s)))
        continue
      }
      s.remove(at: s.startIndex) // Removing color code
      if token.count > 0 { attributedElements.append((attribute: colorCode, string: String(s))) }
    }
    // Generating attributed string
    attributed = NSMutableAttributedString(string: "")
    for element in attributedElements {
      attributed.append(NSAttributedString(
        string: element.string,
        attributes: [.foregroundColor:NSColor(hex: element.attribute.hex) ?? .white]
      ))
    }
  }
  
}
