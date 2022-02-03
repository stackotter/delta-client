import Foundation

extension World.Event {
  public struct SetBlock: Event {
    public let position: Position
    public let newState: Int
    
    public init(position: Position, newState: Int) {
      self.position = position
      self.newState = newState
    }
  }
}
