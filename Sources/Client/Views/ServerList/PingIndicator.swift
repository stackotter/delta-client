import SwiftUI

struct PingIndicator: View {
  let color: Color
  
  var body: some View {
    Circle()
      .foregroundColor(color)
      .fixedSize()
  }
}
