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
      inputCaptured = false
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
}
