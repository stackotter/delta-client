import Foundation

extension World.Event {
  public struct SetBlock: Event {
    let position: Position
    let newState: UInt16
  }
}
