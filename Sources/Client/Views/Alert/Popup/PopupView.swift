import SwiftUI


// MARK: - PopupView


/// Displays a popup on top of the screen with a title, subtitle. icon and two action buttons
struct PopupView: View {
  
  // MARK: - Properties.UI
  
  
  /// Popup title
  private let title: String
  /// Popup subtitle
  private let subtitle: String
  /// Image displayed to the left of the title and subtitle
  private var icon: Image? = nil
  /// Color of the inner thick border around the banner and of the confirm/cancel buttons
  private let secondaryColor = Colors.secondaryDarkGray.color
  /// Banner background color
  private let backgroundColor = Colors.primaryDarkGray.color
  
  
  // MARK: - Properties.bindings
  
  
  private var onConfirm: (() -> Void)? = nil
  private var onCancel: (() -> Void)? = nil
  
  
  // MARK: - Init
  
  
  typealias Action = (confirm: (() -> Void), cancel: () -> Void)
  init(title: String, subtitle: String, icon: Image? = nil, action: Action? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.onCancel = action?.cancel
    self.onConfirm = action?.confirm
  }
  
  
  // MARK: - Methods.View
  
  
  var body: some View {
    GeometryReader{ geometry in
      let parentWidth = geometry.size.width
      let bannerMinWidth = parentWidth * 0.25
      let bannerMinHeight: CGFloat = 50
      let bannerTopPadding = geometry.size.height * 0.05
      let contentHorizontalPadding: CGFloat = 25
      let contentVerticalPadding: CGFloat = 10
      let iconSize: CGFloat = 25
      
      VStack(alignment: .center, spacing: 0) {
        HStack(spacing: contentHorizontalPadding) { // Banner
          if let image = icon {
            image // Icon
              .resizable()
              .aspectRatio(1, contentMode: .fit)
              .frame(width: iconSize)
          }
          
          VStack(alignment: .leading) {
            Text(title) // Title
              .textStyle(WarningTextStyle())
              .multilineTextAlignment(.leading)
            Text(subtitle) // Subtitle
              .textStyle(DefaultPopupTextStyle())
              .multilineTextAlignment(.leading)
          }
        }
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.vertical, contentVerticalPadding)
        .frame(minWidth: bannerMinWidth, alignment: .leading)
        .frame(minHeight: bannerMinHeight)
        .background(backgroundColor)
        .clipShape(
          PopupBorder() // Clipping background to border
        )
        .overlay(
          ZStack { // Border
            PopupBorder() // Inner border
              .strokeBorder(secondaryColor, lineWidth: 6)
            PopupBorder() // Outer border
              .stroke(Color.black, lineWidth: 2.5)
          }
        )
        
        if let confirmAction = onConfirm, let cancelAction = onCancel {
          HStack(spacing: 20) {
            generateButton(with: "Cancel", and: cancelAction)
            generateButton(with: "Confirm", and: confirmAction)
          }
        }
        
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding(.top, bannerTopPadding)
    }
  }
  
  
  // MARK: - Methods.UI
  
  
  /// Creates a pre-styled button
  ///
  /// - Parameters:
  ///   - title: the button title
  ///   - action: the action to be triggered on button press
  /// - Returns: the button
  @ViewBuilder private func generateButton(with title: String, and action: @escaping (() -> Void)) -> some View {
    Button(title) {
      action()
    }
    .buttonStyle(PaddedButtonStyle(backgroundColor: secondaryColor))
    .overlay(
      RoundedRectangle(cornerRadius: 2)
        .stroke(Color.black, lineWidth: 1.5)
    )
  }
  
}

