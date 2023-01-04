import SwiftUI
import DeltaCore
import GameController

#if os(macOS)
import Carbon
#endif

final class ClientInputDelegate: InputDelegate {
  /// ``mouseSensitivity`` is multiplied by this factor before use.
  let sensitivityAdjustmentFactor: Float = 0.004

  var mouseSensitivity = ConfigManager.default.config.mouseSensitivity

  var client: Client

  @Binding var cursorCaptured: Bool
  var pressedKeys: Set<Key> = []

  init(for client: Client) {
    self.client = client

    // Use a dummy binding until `bind(_:)` is called.
    _cursorCaptured = Binding<Bool>(get: { true }, set: { _ in })

    // Function to run intially to lookout for any MFI or Remote Controllers in the area
    NotificationCenter.default.addObserver(self, selector: #selector(connectControllers), name: NSNotification.Name.GCControllerDidConnect, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(disconnectControllers), name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
  }

  @objc func disconnectControllers() {
    client.moveLeftThumbstick(0, 0)
    client.moveRightThumbstick(0, 0)
  }

  @objc func connectControllers() {
    print("controller: \(GCController.controllers())")
    for controller in GCController.controllers() {
      if let pad = controller.extendedGamepad {
        print("found controller with pad")
        pad.valueChangedHandler = { [weak self] pad, element in
          print("event")
          print(element)
          guard let self = self else { return }

          if element == pad.buttonA {
            if pad.buttonA.isPressed {
              self.client.press(.jump)
            } else {
              self.client.release(.jump)
            }
          } else if element == pad.leftThumbstick {
            print("move left")
            self.client.moveLeftThumbstick(
              pad.leftThumbstick.xAxis.value,
              pad.leftThumbstick.yAxis.value
            )
          } else if element == pad.rightThumbstick {
            print("move right")
            self.client.moveRightThumbstick(
              pad.rightThumbstick.xAxis.value,
              pad.rightThumbstick.yAxis.value
            )
          }
        }
      }
    }
  }

  func bind(_ cursorCaptured: Binding<Bool>) {
    _cursorCaptured = cursorCaptured
  }

  func onKeyDown(_ key: Key, _ characters: [Character] = []) {
    pressedKeys.insert(key)
    client.press(key, characters)
  }

  func onKeyUp(_ key: Key) {
    pressedKeys.remove(key)
    client.release(key)
  }

  func onMouseMove(_ deltaX: Float, _ deltaY: Float) {
    let sensitivity = sensitivityAdjustmentFactor * mouseSensitivity
    client.moveMouse(sensitivity * deltaX, sensitivity * deltaY)
  }

  func releaseCursor() {
    for key in pressedKeys {
      client.release(key)
    }

    pressedKeys = []

    #if os(macOS)
    if cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
    }
    #endif
    cursorCaptured = false
  }

  func captureCursor() {
    #if os(macOS)
    if !cursorCaptured {
      CGAssociateMouseAndMouseCursorPosition(0)
      NSCursor.hide()
    }
    #endif
    cursorCaptured = true
  }
}
