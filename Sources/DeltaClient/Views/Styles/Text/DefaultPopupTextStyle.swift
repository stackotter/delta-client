import SwiftUI


// MARK: - DefaultPopupTextStyle


struct DefaultPopupTextStyle: TextStyle {
  
  // MARK: - Properties.UI
  
  
  private let textColor = Color.white
  
  
  // MARK: - Methods.TextStyle
  
  
  func makeBody(configuration: Text) -> Text {
    configuration
      .font(.system(size: 18, weight: .regular))
      .foregroundColor(textColor)
  }
  
}
