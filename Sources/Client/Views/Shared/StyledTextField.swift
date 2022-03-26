import SwiftUI

struct StyledTextField: View {
  /// Textfield placeholder
  let title: String
  /// Textfield's text
  @Binding var text: String
  
  var body: some View {
    TextField(title, text: $text)
      .font(Font.custom(.worksans, size: 15.5))
      .textFieldStyle(PlainTextFieldStyle())
      .padding()
      .foregroundColor(.white)
      .background(Color.clear)
      .frame(maxWidth: .infinity)
      .frame(height: 40)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.lightGray, lineWidth: 2)
      )
  }
}
