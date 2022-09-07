import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import CoreGraphics
import UIKit
#endif

/// Text formatted using legacy formatting codes.
///
/// [See the wiki for more information on legacy formatting codes](https://minecraft.fandom.com/wiki/Formatting_codes)
public struct LegacyFormattedText {
  /// The styled tokens that form the text.
  public var tokens: [Token]

  /// Parses a string containing legacy formatting codes into styled tokens.
  public init(_ string: String) {
    // This will always succeed because lenient parsing doesn't throw any errors
    // swiftlint:disable force_try
    self = try! Self.parse(string, strict: false)
    // swiftlint:enable force_try
  }

  /// Creates legacy formatted text from tokens.
  public init(_ tokens: [Token]) {
    self.tokens = tokens
  }

  /// When `strict` is `true`, no errors are thrown.
  public static func parse(_ string: String, strict: Bool) throws -> LegacyFormattedText {
    var tokens: [Token] = []

    var currentColor: Color?
    var currentStyle: Style?
    let parts = string.split(separator: "§", omittingEmptySubsequences: false)
    for (i, part) in parts.enumerated() {
      // First token always has no formatting code
      if i == 0 {
        guard part != "" else {
          continue
        }
        tokens.append(Token(string: String(part), color: nil, style: nil))
        continue
      }

      // First character is formatting code
      guard let character = part.first else {
        if strict {
          throw LegacyFormattedTextError.missingFormattingCodeCharacter
        }
        continue
      }

      // Rest is content
      let content = String(part.dropFirst())

      guard let code = FormattingCode(rawValue: character) else {
        if strict {
          throw LegacyFormattedTextError.invalidFormattingCodeCharacter(character)
        }
        tokens.append(Token(string: content, color: nil, style: nil))
        continue
      }

      // Update formatting state
      switch code {
        case .style(.reset):
          currentStyle = nil
          currentColor = nil
        case let .color(color):
          currentColor = color
          // Using a color code resets the style in Java Edition
          currentStyle = nil
        case let .style(style):
          currentStyle = style
      }

      guard !content.isEmpty else {
        continue
      }

      tokens.append(Token(string: content, color: currentColor, style: currentStyle))
    }

    return LegacyFormattedText(tokens)
  }

  /// - Returns: The string as plaintext (with styling removed)
  public func toString() -> String {
    return tokens.map(\.string).joined()
  }

  /// Creates an attributed string representing the formatted text.
  /// - Parameter fontSize: The size of font to use.
  /// - Returns: The formatted string.
  public func attributedString(fontSize: CGFloat) -> NSAttributedString {
    let font = FontUtil.systemFont(ofSize: fontSize)

    let output = NSMutableAttributedString(string: "")
    for token in tokens {
      var attributes: [NSAttributedString.Key: Any] = [:]
      var font = font

      if let color = token.color {
        let color = ColorUtil.color(fromHexString: color.hex)
        attributes[.foregroundColor] = color
        attributes[.strikethroughColor] = color
        attributes[.underlineColor] = color
      }

      if let style = token.style {
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

      output.append(NSAttributedString(
        string: token.string,
        attributes: attributes
      ))
    }

    return output
  }
}
