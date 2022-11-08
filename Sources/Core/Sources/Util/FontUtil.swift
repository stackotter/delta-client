public enum FontUtil {}

// TODO: Move to Delta Client because it's not cross-platform

#if os(macOS)
import AppKit

extension NSFont {
  public func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return NSFont(descriptor: descriptor, size: pointSize)
  }

  public func italics() -> NSFont? {
    return withTraits(.italic)
  }

  public func bold() -> NSFont? {
    return withTraits(.bold)
  }
}

extension FontUtil {
  public static func systemFont(ofSize size: CGFloat) -> NSFont {
    return NSFont.systemFont(ofSize: size)
  }

  public static func systemFontSize(for size: NSControl.ControlSize) -> CGFloat {
    return NSFont.systemFontSize(for: size)
  }
}
#elseif os(iOS)
import UIKit

extension UIFont {
  public func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
      return nil
    }
    return UIFont(descriptor: descriptor, size: pointSize)
  }

  public func italics() -> UIFont? {
    return withTraits(.traitItalic)
  }

  public func bold() -> UIFont? {
    return withTraits(.traitBold)
  }
}

extension FontUtil {
  public enum ControlSize {
    case regular
  }

  public static func systemFont(ofSize size: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: size)
  }

  public static func systemFontSize(for: ControlSize) -> CGFloat {
    return 14
  }
}
#endif
