import SwiftUI
import DeltaCore

#if os(macOS)
import Carbon

final class ClientInputDelegate: InputDelegate {
  /// ``mouseSensitivity`` is multiplied by this factor before use.
  let sensitivityAdjustmentFactor: Float = 0.004
  
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
    
    if key == .escape {
      releaseCursor()
    }
    
    if let input = keymap.getInput(for: key) {
      client.press(input)
    }
  }
  
  func onKeyUp(_ key: Key) {
    pressedKeys.remove(key)
    
    if let input = keymap.getInput(for: key) {
      client.release(input)
    }
  }
  
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
    let sensitivity = sensitivityAdjustmentFactor * mouseSensitivity
    client.moveMouse(sensitivity * deltaX, sensitivity * deltaY)
  }
  
  func releaseCursor() {
    for key in pressedKeys {
      if let input = keymap.getInput(for: key) {
        client.release(input)
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
#elseif os(iOS)
final class ClientInputDelegate: InputDelegate {
  /// ``mouseSensitivity`` is multiplied by this factor before use.
  let sensitivityAdjustmentFactor: Float = 0.004

  var keymap = ConfigManager.default.config.keymap
  var mouseSensitivity = ConfigManager.default.config.mouseSensitivity
  
  var client: Client
  
  @Binding var cursorCaptured: Bool
  
  init(for client: Client) {
    self.client = client
    _cursorCaptured = Binding<Bool>(get: { true }, set: { _ in })
  }
  
  func bind(_ cursorCaptured: Binding<Bool>) {
    _cursorCaptured = cursorCaptured
  }
  
  func onKeyDown(_ key: Key) {
  }
  
  func onKeyUp(_ key: Key) {
  }
  
  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
  }
  
  func releaseCursor() {
    cursorCaptured = false
  }
  
  func captureCursor() {
    cursorCaptured = true
  }
}
#else
#error("Unsupported platform, no input delegate")
#endif
