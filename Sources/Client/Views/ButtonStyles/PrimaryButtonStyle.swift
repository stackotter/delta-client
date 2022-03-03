import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  var height: CGFloat? = nil
  
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label
      Spacer()
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .frame(height: height)
    .background(Color.darkGray)
    .cornerRadius(4)
  }
}
