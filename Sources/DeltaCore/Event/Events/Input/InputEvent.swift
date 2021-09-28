import Foundation

public struct InputEvent: Event {
  public var type: InputEventType
  public var input: Input
  
  public init(type: InputEventType, input: Input) {
    self.type = type
    self.input = input
  }
}
