import SwiftUI
import DeltaCore

struct KeyMappingEditorView: View {
  /// Whether key inputs are being captured by the view
  @Binding var inputCaptured: Bool
  
  /// A wrapper for the current key mapping and the currently selected input
  @ObservedObject var state: KeyMappingEditorState
  
  init(inputCaptured: Binding<Bool>, inputDelegateSetter setInputDelegate: (InputDelegate) -> Void) {
    _inputCaptured = inputCaptured
    state = KeyMappingEditorState(keyMapping: ConfigManager.default.config.keybinds.mapping)
    let inputDelegate = ControlsEditorInputDelegate(controlsState: state, inputCaptured: _inputCaptured)
    setInputDelegate(inputDelegate)
  }
  
  var body: some View {
    VStack {
      ForEach(Input.allCases, id: \.self) { input in
        let key = state.keyMapping[input]
        let isUnique = key == nil ? true : state.keyMapping.values.filter({ $0 == key }).count == 1
        let isBound = state.keyMapping[input] != nil
        let isSelected = state.selectedInput == input
        
        let labelColor = Self.labelColor(isUnique: isUnique, isBound: isBound, isSelected: isSelected)
        
        HStack {
          Text(input.humanReadableLabel)
            .frame(width: 150)
          
          let keyName = state.keyMapping[input]?.humanReadableLabel ?? "Unbound"
          Button(action: {
            if isSelected {
              state.selectedInput = nil
              inputCaptured = false
            } else {
              state.selectedInput = input
              inputCaptured = true
            }
          }, label: {
            Text(isSelected ? "> Press key <" : keyName)
              .foregroundColor(labelColor)
          })
          .buttonStyle(SecondaryButtonStyle())
          
          IconButton("xmark", isDisabled: !isBound || isSelected) {
            state.keyMapping[input] = nil
          }
        }
        .frame(width: 400)
      }
    }
  }
  
  static func labelColor(isUnique: Bool, isBound: Bool, isSelected: Bool) -> Color {
    if isSelected {
      return .white
    } else if !isBound {
      return .yellow
    } else if !isUnique {
      return .red
    } else {
      return .white
    }
  }
}
