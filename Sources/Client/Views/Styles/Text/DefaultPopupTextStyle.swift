import SwiftUI


// MARK: - DefaultPopupTextStyle


struct DefaultPopupTextStyle: TextStyle {
  private let textColor = Color.white
  
  
  func makeBody(configuration: Text) -> Text {
    configuration
      .font(.system(size: 18, weight: .regular))
      .foregroundColor(textColor)
  }
}
