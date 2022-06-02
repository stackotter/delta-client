import Foundation

extension World.Event {
  public struct SetBlock: Event {
    public let position: BlockPosition
    public let newState: Int
    
    public init(position: BlockPosition, newState: Int) {
      self.position = position
      self.newState = newState
    }
  }
}
