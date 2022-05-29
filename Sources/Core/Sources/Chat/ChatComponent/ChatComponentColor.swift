import Foundation

extension ChatComponent {
  /// A component's color.
  public enum Color: String, Codable, Equatable {
    // TODO: handle hex code colors
    case white
    case black
    case gray
    case darkGray = "dark_gray"
    case red
    case darkRed = "dark_red"
    case gold
    case yellow
    case green
    case darkGreen = "dark_green"
    case aqua
    case darkAqua = "dark_aqua"
    case blue
    case darkBlue = "dark_blue"
    case purple = "light_purple"
    case darkPurple = "dark_purple"
    case reset
  }
}
