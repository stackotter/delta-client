import SwiftUI


// MARK: - WarningTextStyle


struct WarningTextStyle: TextStyle {
  private let warningTextColor = Colors.warningYellow
  
  
  func makeBody(configuration: Text) -> Text {
    configuration
      .font(.system(size: 18, weight: .regular))
      .foregroundColor(warningTextColor)
  }
}
