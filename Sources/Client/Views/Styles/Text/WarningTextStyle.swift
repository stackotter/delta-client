import SwiftUI


// MARK: - WarningTextStyle


struct WarningTextStyle: TextStyle {
  
  // MARK: - Properties.UI
  
  
  private let warningTextColor = Colors.warningYellow.color
  
  
  // MARK: - Methods.TextStyle
  
  
  func makeBody(configuration: Text) -> Text {
    configuration
      .font(.system(size: 18, weight: .regular))
      .foregroundColor(warningTextColor)
  }
  
}
