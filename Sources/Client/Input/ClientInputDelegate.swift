import SwiftUI
import DeltaCore
import Carbon

#if os(macOS)
final class ClientInputDelegate: InputDelegate {
  /// ``mouseSensitivity`` is multiplied by this factor before use.
  let sensitivityAdjustmentFactor: Float = 0.2
  
  var keymap = ConfigManager.default.config.keymap
  var mouseSensitivity = ConfigManager.default.config.mouseSensitivity
  
  var client: Client
  
  @Binding var cursorCaptured: Bool
  var pressedKeys: Set<Key> = []
  
  init(for client: Client) {
    self.client = client
    
    // Use a dummy binding until `bind(_:)` is called.
    _cursorCaptured = Binding<Bool>(get: { true }, set: { _ in })
  }
  
  func bind(_ cursorCaptured: Binding<Bool>) {
    _cursorCaptured = cursorCaptured
  }
  
  func onKeyDown(_ key: Key) {
    pressedKeys.insert(key)
    
    // Release cursor when escape is pressed
    if key == .code(53) {
      releaseCursor()
    }
    
    if let input = keymap.getInput(for: key) {
      let event = InputEvent(type: .press, input: input)
      client.eventBus.dispatch(event)
    }
  }
  
  func onKeyUp(_ key: Key) {
    pressedKeys.remove(key)
    
    if let input = keymap.getInput(for: key) {
      let event = InputEvent(type: .release, input: input)
      client.eventBus.dispatch(event)
    }
  }
  
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
    let sensitivity = sensitivityAdjustmentFactor * mouseSensitivity
    let event = MouseMoveEvent(deltaX: sensitivity * deltaX, deltaY: sensitivity * deltaY)
    client.eventBus.dispatch(event)
  }
  
  func releaseCursor() {
    for key in pressedKeys {
      if let input = keymap.getInput(for: key) {
        let event = InputEvent(type: .release, input: input)
        client.eventBus.dispatch(event)
      }
    }
    
    pressedKeys = []
    
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
