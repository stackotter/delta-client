import SwiftUI
import DeltaCore

class ControlsEditorInputDelegate: InputDelegate {
  let controlsState: ControlsState
  @Binding var inputCaptured: Bool
  
  init(controlsState: ControlsState, inputCaptured: Binding<Bool>) {
	  self.controlsState = controlsState
    _inputCaptured = inputCaptured
  }
  
  func onKeyDown(_ key: Key) {
    defer {
      controlsState.selectedInput = nil
      inputCaptured = false
    }
    
    guard let selectedInput = controlsState.selectedInput else {
      return
    }
    
    if case .code(let code) = key, code == 53 {
      controlsState.keyMapping.removeValue(forKey: selectedInput)
    } else {
      controlsState.keyMapping[selectedInput] = key
    }
    
    var config = ConfigManager.default.config
    config.keybinds.mapping = controlsState.keyMapping
    ConfigManager.default.setConfig(to: config)
  }
}
