enum ColorUtil {}

// TODO: Move ColorUtil to Client target (instead of Core) because it's not cross-platform

#if canImport(AppKit)
import AppKit

extension NSColor {
  /// Creates `NSColor` from hex string
  ///
  /// - Parameters:
  ///   - hexString: the hex string representation of the color
  ///   - alpha: the color alpha
  convenience init?(hexString: String, alpha: CGFloat = 1) {
    var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])

    switch chars.count {
      case 3: chars = chars.flatMap { [$0, $0] }
      case 6: break
      default: return nil
    }

    guard
      let red = Int(String(chars[0..<2]), radix: 16),
      let green = Int(String(chars[2..<4]), radix: 16),
      let blue = Int(String(chars[4..<6]), radix: 16)
    else {
      return nil
    }

    self.init(
      red: CGFloat(red) / 255,
      green: CGFloat(green) / 255,
      blue: CGFloat(blue) / 255,
      alpha: alpha
    )
  }
}

extension ColorUtil {
  static func color(fromHexString hexString: String, alpha: CGFloat = 1) -> NSColor? {
    return NSColor(hexString: hexString)
  }
}
#elseif canImport(UIKit)
import UIKit

extension UIColor {
  /// Creates `UIColor` from hex string
  ///
  /// - Parameters:
  ///   - hexString: the hex string representation of the color
  ///   - alpha: the color alpha
  convenience init?(hexString: String, alpha: CGFloat = 1) {
    var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])

    switch chars.count {
      case 3: chars = chars.flatMap { [$0, $0] }
      case 6: break
      default: return nil
    }

    guard
      let red = Int(String(chars[0..<2]), radix: 16),
      let green = Int(String(chars[2..<4]), radix: 16),
      let blue = Int(String(chars[4..<6]), radix: 16)
    else {
      return nil
    }

    self.init(
      red: CGFloat(red) / 255,
      green: CGFloat(green) / 255,
      blue: CGFloat(blue) / 255,
      alpha: alpha
    )
  }
}

extension ColorUtil {
  static func color(fromHexString hexString: String, alpha: CGFloat = 1) -> UIColor? {
    return UIColor(hexString: hexString)
  }
}
#endif
