import SwiftUI


struct StyledButton: View {
  
  /// Callback triggered on button tap
  let action: (() -> Void)?
  /// Button's height
  var height: CGFloat? = nil
  /// Button image
  var icon: Image? = nil
  /// Button title
  var text: String? = nil
  
  
  var body: some View {
    Button { action?() } label: {
      HStack(alignment: .center) {
        if let image = icon {
          image
            .foregroundColor(.white)
            .font(Font.system(size: 15, weight: .medium))
        }
        if let text = text {
          Text(text)
            .font(Font.custom(.worksans, size: 14))
            .foregroundColor(.white)
        }
      }
    }
    .buttonStyle(PrimaryButtonStyle(height: height))
  }
}
