#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A simple helper for managing the user's clipboard.
enum Clipboard {
  /// Sets the contents of the user's clipboard to a given string.
  static func copy(_ contents: String) {
    #if canImport(AppKit)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(contents, forType: .string)
    #elseif os(iOS)
      UIPasteboard.general.string = contents
    #elseif os(tvOS)
      #warning("Remove dependence on copy on tvOS")
    #else
      #error("Unsupported platform, unknown clipboard implementation")
    #endif
  }
}
