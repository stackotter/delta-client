import SwiftUI
import DeltaCore

struct ControlsEditorView: View {
  
  /// Whether key inputs are being captured by the view
  @Binding var inputCaptured: Bool
  
  /// A wrapper for the current key mapping and the currently selected input
  @ObservedObject var controlsState: ControlsState
  
  init(inputCaptured: Binding<Bool>, inputDelegateSetter setInputDelegate: (InputDelegate) -> Void) {
    _inputCaptured = inputCaptured
    controlsState = ControlsState(keyMapping: ConfigManager.default.config.keybinds.mapping)
    let inputDelegate = ControlsEditorInputDelegate(controlsState: controlsState, inputCaptured: _inputCaptured)
    setInputDelegate(inputDelegate)
  }
  
  var body: some View {
    VStack {
      ForEach(Input.allCases, id: \.self) { input in
        HStack {
          Text(input.humanReadableLabel)
            .frame(width: 150)
          Divider()
          Text(controlsState.keyMapping[input]?.humanReadableLabel ?? "Unbound")
          Button(controlsState.selectedInput == input ? "Press Key..." : "Change") {
            controlsState.selectedInput = input
            inputCaptured = true
          }
            .buttonStyle(SecondaryButtonStyle())
        }
          .frame(width: 400)
      }
    }
  }
}
