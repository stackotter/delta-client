import SwiftUI

#if os(tvOS)
  typealias PrimaryButtonStyle = DefaultButtonStyle
#else
  struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      HStack {
        Spacer()
        configuration.label.foregroundColor(.white)
        Spacer()
      }
      .padding(6)
      .background(Color.accentColor.brightness(configuration.isPressed ? 0.15 : 0).cornerRadius(4))
    }
  }
#endif
