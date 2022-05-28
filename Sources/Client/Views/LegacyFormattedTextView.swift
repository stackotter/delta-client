import Foundation
import DeltaCore
import SwiftUI

/// SwiftUI view for displaying text that is formatted using Legacy formatting codes.
///
/// See ``LegacyTextFormatter``.
struct LegacyFormattedTextView: View {
  /// The legacy formatted string.
  var string: String
  /// The formatted text.
  var attributedString = NSAttributedString(string: "")
  /// The font size.
  var fontSize: CGFloat
  /// The alignment of the text.
  var alignment: NSTextAlignment = .center
  
  init(legacyString: String, fontSize: CGFloat, alignment: NSTextAlignment = .center) {
    self.string = legacyString
    self.attributedString = LegacyFormattedText(legacyString).attributedString(fontSize: fontSize)
    self.fontSize = fontSize
    self.alignment = alignment
  }
  
  var body: some View {
    NSAttributedTextView(
      attributedString: attributedString,
      alignment: alignment
    ).frame(width: attributedString.size().width)
  }
}

struct NSAttributedTextView: NSViewRepresentable {
  var attributedString: NSAttributedString
  var alignment: NSTextAlignment
  
  func makeNSView(context: Context) -> some NSView {
    let label = NSTextField()
    label.backgroundColor = .clear
    label.isBezeled = false
    label.isEditable = false
    return label
  }
  
  func updateNSView(_ nsView: NSViewType, context: Context) {
    guard let label = nsView as? NSTextField else { return }
    label.attributedStringValue = attributedString
    label.alignment = .left
  }
}
