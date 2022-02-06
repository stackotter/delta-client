import SwiftUI

extension Font {
  /// Fonts provided by the application- Raw value is the font string identifier
  public enum CustomFontType: String {
    case minecraft = "minecraft"
    case worksans = "WorkSans-Regular"
  }
  
  /// - Parameters:
  ///   - type: the font preset
  ///   - size: the font size
  /// - Returns: the custom font
  public static func custom(_ type: CustomFontType, size: CGFloat) -> Font {
    return Font.custom(type.rawValue, size: size)
  }
}
