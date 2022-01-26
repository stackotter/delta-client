import SwiftUI

struct ProgressLoadingView: View {
  // MARK: Public properties
  
  /// Loader progress
  public var progress: Double {
    didSet {
      if progress < 0 || progress > 1 {
        log.error("Progress out of range: \(progress)")
      }
    }
  }
  
  /// Loading message
  public var message: String
  
  // MARK: Private properties
  
  /// Loader bar border height
  private let loaderHeight: CGFloat = 20
  /// Loader bar border width
  private let loaderSize: CGFloat = 4
  /// Bar inset
  private let inset: CGFloat = 6
  
  // MARK: View
  
  var body: some View {
    GeometryReader { proxy in
      let parentWidth = proxy.size.width
      let loaderWidth = parentWidth * 0.6
      let progressBarWidth = loaderWidth - 2 * inset
      
      VStack(alignment: .center) {
        Text(message)
        
        HStack(alignment: .center) {
          Color.white
            .frame(width: progressBarWidth * progress)
            .frame(maxHeight: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 1))
          Spacer()
        }
        .padding(.horizontal, inset)
        .padding(.vertical, inset)
        .frame(width: loaderWidth, height: loaderHeight)
        .overlay(
          PixellatedBorder()
            .stroke(Color.white, lineWidth: loaderSize)
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .background(Color.black)
    }
  }
}
