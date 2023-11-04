#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// A simple helper for managing the user's clipboard.
enum Clipboard {
  /// Sets the contents of the user's clipboard to a given string.
  static func copy(_ contents: String) {
    #if os(macOS)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(contents, forType: .string)
    #elseif os(iOS)
      UIPasteboard.general.string = contents
    #else
      #error("Unsupported platform, unknown clipboard implementation")
    #endif
  }
}
