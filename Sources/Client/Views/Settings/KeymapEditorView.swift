import SwiftUI
import DeltaCore

struct KeymapEditorView: View {
  
  /// Whether key inputs are being captured by the view
  @Binding var inputCaptured: Bool

  /// A wrapper for the current keymap and the currently selected input
  @ObservedObject var state: KeymapEditorState

  init(inputCaptured: Binding<Bool>, inputDelegateSetter setInputDelegate: (InputDelegate) -> Void) {
    _inputCaptured = inputCaptured
    state = KeymapEditorState(keymap: ConfigManager.default.config.keymap.bindings)
    let inputDelegate = KeymapEditorInputDelegate(editorState: state, inputCaptured: _inputCaptured)
    setInputDelegate(inputDelegate)
  }

  var body: some View {
    VStack(spacing: 15) {
      ForEach(Input.allCases.filter(\.isBindable), id: \.self) { input in
        let key = state.keymap[input]
        let isUnique = key == nil ? true : state.keymap.values.filter({ $0 == key }).count == 1
        let isBound = state.keymap[input] != nil
        let isSelected = state.selectedInput == input

        let labelColor = Self.labelColor(isUnique: isUnique, isBound: isBound, isSelected: isSelected)

        HStack {
          // Input name (e.g. 'Sneak')
          Text(input.humanReadableLabel)
            .font(Font.custom(.worksans, size: 15))
            .foregroundColor(.white)

          // Button to set a new binding
          let keyName = state.keymap[input]?.rawValue ?? "Unbound"
          Button(action: {
            if isSelected {
              state.keymap[input] = .leftMouseButton
              state.selectedInput = nil
              inputCaptured = false
            } else {
              state.selectedInput = input
              inputCaptured = true
            }
          }, label: {
            Text(isSelected ? "> Press key <" : keyName)
              .font(Font.custom(.worksans, size: 14))
              .foregroundColor(labelColor)
          })
          .buttonStyle(SecondaryButtonStyle())
          .frame(width: 150)

          // Button to unbind an input
          IconButton("xmark", isDisabled: !isBound || isSelected) {
            state.keymap.removeValue(forKey: input)
            var config = ConfigManager.default.config
            config.keymap.bindings = state.keymap
            ConfigManager.default.setConfig(to: config)
          }
        }
      }
    }
  }

  static func labelColor(isUnique: Bool, isBound: Bool, isSelected: Bool) -> Color {
    if isSelected { return .white }
    else if !isBound { return .yellow }
    else if !isUnique { return .red }
    else { return .white }
  }
}
