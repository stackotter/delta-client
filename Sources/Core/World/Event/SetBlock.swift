import Foundation

extension World.Event {
  struct SetBlock: Event {
    let position: Position
    let newState: Int
  }
}
