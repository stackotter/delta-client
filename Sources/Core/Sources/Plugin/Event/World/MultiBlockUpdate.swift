import Foundation

extension World.Event {
  /// An event triggered when multiple blocks are updated at once.
  public struct MultiBlockUpdate: Event {
    public let updates: [SingleBlockUpdate]
  }
}
