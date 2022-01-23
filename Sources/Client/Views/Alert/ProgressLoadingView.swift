import SwiftUI


// MARK: - ProgressLoadingView


struct ProgressLoadingView: View {
  
  // MARK: - Public properties
  
  
  /// Loader progress
  ///
  /// - Precondition: progress `$\in [0, 1]$`
  public var progress: Double {
    didSet { if progress < 0 || progress > 1 { fatalError("Progress out of range") } }
  }
  /// Loading message
  public var message: String
  
  
  // MARK: - UI properties
  
  
  /// Loader bar height
  private let loaderHeight: CGFloat = 18
  /// Loader bar border width
  private let loaderSize: CGFloat = 5
  /// Loader bar horizontal inset
  private let horizontalInset: CGFloat = 7.5
  
  
  // MARK: - View
  
  
  var body: some View {
    GeometryReader { proxy in
      let parentWidth = proxy.size.width
      let loaderWidth = parentWidth * 0.6
      
      VStack(alignment: .center) {
        Text(message)
        
        HStack(alignment: .center) {
          Color.white
            .frame(width: (loaderWidth-2*horizontalInset) * progress)
            .frame(maxHeight: .infinity, alignment: .leading)
            .clipShape(
              RoundedRectangle(cornerRadius: loaderHeight / 5.5)
            )
            .animation(.easeIn(duration: 0.25))
          Spacer()
        } // Loading bar
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, loaderHeight / 2.75)
        .frame(width: loaderWidth, height: loaderHeight)
        .overlay(
          PixellatedBorder()
            .stroke(Color.white, lineWidth: loaderSize)
        )
      } // VStack
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .background(Color.black)
    }
  }
  
}
