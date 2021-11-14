import SwiftUI
import DeltaCore
import Carbon

#if os(macOS)
class ClientInputDelegate: InputDelegate {
  let keyMapping = ConfigManager.default.config.keybinds
  
  var client: Client
  
  @Binding var cursorCaptured: Bool
  
  init(for client: Client) {
    self.client = client
    
    // Use a dummy binding until `bind(_:)` is called.
    _cursorCaptured = Binding<Bool>(get: { true }, set: { _ in })
  }
  
  func bind(_ cursorCaptured: Binding<Bool>) {
    _cursorCaptured = cursorCaptured
  }
  
  func onKeyDown(_ key: Key) {
    // Release
    if key == .code(53) {
      releaseCursor()
    }
    
    if let input = keyMapping.getEvent(for: key) {
      let event = InputEvent(type: .press, input: input)
      client.eventBus.dispatch(event)
    }
  }
  
  func onKeyUp(_ key: Key) {
    if let input = keyMapping.getEvent(for: key) {
      let event = InputEvent(type: .release, input: input)
      client.eventBus.dispatch(event)
    }
  }
  
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
    let event = MouseMoveEvent(deltaX: deltaX, deltaY: deltaY)
    client.eventBus.dispatch(event)
  }
  
  func releaseCursor() {
    if cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
    }
    cursorCaptured = false
  }
  
  func captureCursor() {
    if !cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(0)
      NSCursor.hide()
    }
    cursorCaptured = true
  }
}
#endif
