import Foundation
import Parsing
import AppKit

/// Text formatted using legacy formatting codes.
///
/// [See the wiki for more information on legacy formatting codes](https://minecraft.fandom.com/wiki/Formatting_codes)
public struct LegacyFormattedText {
  /// The styled tokens that form the text.
  public var tokens: [Token]

  /// A parser that splits a string into formatted tokens.
  private static let tokenizer = Many {
    OneOf {
      Parse {
        "§"
        First().map(FormattingCode.init(rawValue:))
        OneOf {
          PrefixUpTo("§")
          Rest()
        }.map(String.init)
      }

      Parse {
        OneOf {
          PrefixUpTo("§")
          Rest()
        }.map(String.init)
      }.map { string in
        return (FormattingCode?.none, string)
      }
    }
  }

  /// Parses a string containing legacy formatting codes into styled tokens.
  public init(_ string: String) {
    let tokenized: [(formattingCode: FormattingCode?, string: String)]
    do {
      tokenized = try Self.tokenizer.parse(string)
    } catch {
      log.warning("Failed to parse legacy formatted text: \(error)")
      tokens = [Token(string: string, color: nil, style: nil)]
      return
    }

    tokens = []
    var currentColor: Color?
    var currentStyle: Style?
    for token in tokenized {
      if let formattingCode = token.formattingCode {
        switch formattingCode {
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
      }
      
      guard !token.string.isEmpty else {
        continue
      }

      tokens.append(Token(string: token.string, color: currentColor, style: currentStyle))
    }
  }

  /// Creates an attributed string representing the formatted text.
  /// Parameter fontSize: The size of font to use.
  /// Returns: The formatted string.
  public func attributedString(fontSize: CGFloat) -> NSAttributedString {
    let font = NSFont.systemFont(ofSize: fontSize)

    let output = NSMutableAttributedString(string: "")
    for token in tokens {
      var attributes: [NSAttributedString.Key: Any] = [:]
      var font = font
      
      if let color = token.color {
        let color = NSColor(hexString: color.hex)
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
