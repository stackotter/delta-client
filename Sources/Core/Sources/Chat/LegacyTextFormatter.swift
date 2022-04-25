import Foundation
import AppKit

/// A formatter that formats legacy formatted text.
///
/// [See the wiki for more information on legacy text formatting](https://minecraft.fandom.com/wiki/Formatting_codes)
public enum LegacyTextFormatter {
  public static func attributedString(from string: String, fontSize: CGFloat) -> NSAttributedString {
    let font = NSFont.systemFont(ofSize: fontSize)
    
    // Gathering text attributes
    let tokenized = string.split(separator: "§")
    
    if tokenized.count == 1 && !string.starts(with: "§") {
      return NSAttributedString(string: string, attributes: [.font: font])
    }
    
    var currentColor: FormattingCode.ColorCode?
    var currentStyle: FormattingCode.StyleCode?
    var formattedTokens: [(String, FormattingCode.ColorCode?, FormattingCode.StyleCode?)] = []
    
    for token in tokenized {
      var token = token
      
      guard let colorCodeCharacter = token.first, let code = FormattingCode(rawValue: colorCodeCharacter) else {
        formattedTokens.append((String(token), nil, nil))
        continue
      }
      
      switch code {
        case .style(.reset):
          currentStyle = nil
          currentColor = nil
        case let .color(color):
          currentColor = color
        case let .style(style):
          currentStyle = style
      }
      
      token.remove(at: token.startIndex) // Removing color code
      if !token.isEmpty {
        formattedTokens.append((String(token), currentColor, currentStyle))
      }
    }
    
    // Generating attributed string
    let attributed = NSMutableAttributedString(string: "")
    for (string, color, style) in formattedTokens {
      var attributes: [NSAttributedString.Key: Any] = [:]
      var font = font
      
      if let color = color {
        let color = NSColor(hexString: color.hex)
        attributes[.foregroundColor] = color
        attributes[.strikethroughColor] = color
        attributes[.underlineColor] = color
      }
      
      if let style = style {
        switch style {
          case .bold:
            font = font.bold() ?? font
          case .strikethrough:
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
          case .underline:
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
          case .italic:
            font = font.italics() ?? font
          case .reset:
            break
        }
      }
      
      attributes[.font] = font
      
      attributed.append(NSAttributedString(
        string: string,
        attributes: attributes
      ))
    }
    
    return attributed
  }
}
