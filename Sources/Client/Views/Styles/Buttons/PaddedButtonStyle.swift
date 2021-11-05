import SwiftUI

// MARK: - PrimaryButtonStyle


/// Button padded to its title that dims its background when tapped
struct PaddedButtonStyle: ButtonStyle {
  
  // MARK: - Properties.UI
  
  
  public var textColor = Color.white
  public var backgroundColor = Color.accentColor
  public var cornerRadius: CGFloat = 2
  
  
  // MARK: - Properties.ButtonStyle
  
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(textColor)
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(
        backgroundColor
          .brightness(configuration.isPressed ? -0.05 : 0)
          .cornerRadius(cornerRadius)
      )
  }
  
}
