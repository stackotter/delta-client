import SwiftUI
import DeltaCore

class KeymapEditorInputDelegate: InputDelegate {
  let editorState: KeymapEditorState
  @Binding var inputCaptured: Bool

  init(editorState: KeymapEditorState, inputCaptured: Binding<Bool>) {
	  self.editorState = editorState
    _inputCaptured = inputCaptured
  }

  func onKeyDown(_ key: Key, _ characters: [Character] = []) {
    defer {
      editorState.selectedInput = nil
    }

    guard let selectedInput = editorState.selectedInput else {
      return
    }

    if key == .escape {
      editorState.keymap.removeValue(forKey: selectedInput)
    } else {
      editorState.keymap[selectedInput] = key
    }

    var config = ConfigManager.default.config
    config.keymap.bindings = editorState.keymap
    ConfigManager.default.setConfig(to: config)
  }

  func onKeyUp(_ key: Key) {
    if key == .leftMouseButton {
      // Release after deadline to fix bug where setting an input as left click will trigger the
      // input selection again making it impossible to set an input to left click.
      DispatchQueue(label: "releaseInput").asyncAfter(deadline: .now().advanced(by: .milliseconds(100))) { [weak self] in
        guard let self = self else { return }
        ThreadUtil.runInMain {
          self.inputCaptured = false
        }
      }
    } else {
      self.inputCaptured = false
    }
  }
}
