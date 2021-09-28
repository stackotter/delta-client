import SwiftUI

struct IconButton: View {
  let icon: String
  let isDisabled: Bool
  let action: () -> Void
  
  init(_ icon: String, isDisabled: Bool = false, action: @escaping () -> Void) {
    self.icon = icon
    self.isDisabled = isDisabled
    self.action = action
  }
  
  var body: some View {
    Button(action: action, label: {
      Image(systemName: icon)
    })
    .buttonStyle(BorderlessButtonStyle())
    .disabled(isDisabled)
  }
}
