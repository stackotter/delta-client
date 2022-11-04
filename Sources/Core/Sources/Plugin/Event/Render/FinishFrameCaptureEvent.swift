import Foundation

/// The event emitted when a GPU frame capture is finished.
public struct FinishFrameCaptureEvent: Event {
  /// The file the capture was outputted to.
  public var file: URL

  public init(file: URL) {
    self.file = file
  }
}
