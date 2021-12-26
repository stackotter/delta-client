import Foundation
import SwiftUI


// MARK: - MCAttributedText


/// `MCAttributedString` SwiftUI wrapper
struct MCAttributedText: View {
  /// `MCAttributedString.string`
  let string: String
  /// Text alignment
  var alignment: NSTextAlignment = .center
  
  /// Attributed string attributes
  @State private var stringAttribtues: [NSAttributedString.Key:Any]?
  
  var body: some View {
    MCAttributedTextRepresentable(
      stringAttributes: $stringAttribtues,
      string: string,
      alignment: alignment
    )
      .frame(width: (string as NSString).size(withAttributes: stringAttribtues).width)
  }
}


// MARK: - MCAttributedTextRepresentable


/// `MCAttributedText` AppKit wrapper
fileprivate struct MCAttributedTextRepresentable: NSViewRepresentable {
  @Binding var stringAttributes: [NSAttributedString.Key:Any]?
  var string: String
  let alignment: NSTextAlignment
  
  
  func makeNSView(context: Context) -> some NSView {
    let label = NSTextField()
    label.backgroundColor = .clear
    label.isBezeled = false
    label.isEditable = false
    return label
  }
  
  func updateNSView(_ nsView: NSViewType, context: Context) {
    guard let label = nsView as? NSTextField else { return }
    let attributedString = MCAttributedString(string: string).attributed
    if let attributedRange = NSRange(attributedString.string) {
      stringAttributes = attributedString.fontAttributes(in: attributedRange)
    }
    label.attributedStringValue = attributedString
    label.alignment = alignment
  }
  
}
