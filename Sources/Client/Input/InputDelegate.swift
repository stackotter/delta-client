import Foundation

protocol InputDelegate: AnyObject {
  func onKeyDown(_ key: Key)
  func onKeyUp(_ key: Key)
  func onMouseMove(_ deltaX: Float, _ deltaY: Float)
  func onScroll(_ deltaY: Float)
}

extension InputDelegate {
  func onKeyDown(_ key: Key) {}
  func onKeyUp(_ key: Key) {}
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {}
  func onScroll(_ deltaY: Float) {}
}
