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
    #if os(tvOS)
      Text(attributedString.string)
    #else
      NSAttributedTextView(
        attributedString: attributedString,
        alignment: alignment
      ).frame(width: attributedString.size().width)
    #endif
  }
}

#if canImport(AppKit)
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
#elseif canImport(UIKit)
struct NSAttributedTextView: UIViewRepresentable {
  var attributedString: NSAttributedString
  var alignment: NSTextAlignment
  
  func makeUIView(context: Context) -> some UIView {
    let label = UILabel()
    label.backgroundColor = .clear
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return label
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
    guard let label = uiView as? UILabel else { return }
    label.attributedText = attributedString
  }
}
#else
#error("Unsupported platform, no NSAttributedTextView")
#endif
