import SwiftUI
import DeltaCore

struct ProgressLoadingView: View {
  // MARK: Public properties

  /// Loader progress
  @State public var progress: Double
  /// Loading message
  public let message: String

  // MARK: Private properties

  /// Loader bar border height
  private let loaderHeight: CGFloat = 20
  /// Loader bar border width
  private let loaderSize: CGFloat = 4
  /// Bar inset
  private let inset: CGFloat = 6
  /// Progress bar width percentage
  @State private var animatedProgress: Double = 0

  // MARK: Init

  /// Creates a new progress bar view.
  /// - Parameters:
  ///   - progress: The progress from 0 to 1.
  ///   - message: A description for the current task.
  init(progress: Double, message: String) {
    if progress < 0 || progress > 1 {
      log.error("Progress out of range: \(progress)")
    }
    self.progress = progress
    self.message = message
  }

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
            .frame(width: progressBarWidth * animatedProgress)
            .frame(maxHeight: .infinity, alignment: .leading)
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
    .onChange(of: progress) { newProgress in
      ThreadUtil.runInMain {
        withAnimation(.easeInOut(duration: 1)) {
          animatedProgress = newProgress
        }
      }
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1)) {
        animatedProgress = progress
      }
    }
  }
}
