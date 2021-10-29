import Foundation

public struct MouseMoveEvent: Event {
  public var deltaX: Float
  public var deltaY: Float
  
  public init(deltaX: Float, deltaY: Float) {
    self.deltaX = deltaX
    self.deltaY = deltaY
  }
}
