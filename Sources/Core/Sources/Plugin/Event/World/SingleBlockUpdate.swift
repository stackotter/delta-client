import Foundation

extension World.Event {
  /// An event triggered when a single block is updated within a chunk. Use in conjunction with
  /// MultiBlockUpdate to receive all block updates.
  public struct SingleBlockUpdate: Event {
    public let position: BlockPosition
    public let newState: Int

    public init(position: BlockPosition, newState: Int) {
      self.position = position
      self.newState = newState
    }
  }
}
