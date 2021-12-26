import SwiftUI

struct DisabledButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label.foregroundColor(.gray)
      Spacer()
    }
    .padding(6)
    .background(Color.secondary.brightness(-0.4).cornerRadius(4))
  }
}
