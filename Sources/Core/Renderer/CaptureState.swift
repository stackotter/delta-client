import Foundation

extension RenderCoordinator {
  /// The state of a GPU frame capture.
  struct CaptureState {
    /// The number of frames remaining.
    var framesRemaining: Int
    /// The file that the capture will be outputted to.
    var outputFile: URL
  }
}
