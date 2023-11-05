import SwiftUI
import DeltaCore

struct KeymapEditorView: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  /// Whether key inputs are being captured by the view
  @Binding var inputCaptured: Bool
  /// A wrapper for the current keymap and the currently selected input
  @ObservedObject var state: KeymapEditorState

  init(
    managedConfig: ManagedConfig,
    inputCaptured: Binding<Bool>,
    inputDelegateSetter setInputDelegate: (InputDelegate) -> Void
  ) {
    // TODO: Refactor InputView so use environment values and environment objects instead of
    //   the stupid delegate pattern (this would mean that we don't need this weird init at all)
    _inputCaptured = inputCaptured
    state = KeymapEditorState(keymap: managedConfig.keymap.bindings)
    let inputDelegate = KeymapEditorInputDelegate(
      managedConfig: managedConfig,
      editorState: state,
      inputCaptured: _inputCaptured
    )
    setInputDelegate(inputDelegate)
  }

  var body: some View {
    VStack {
      ForEach(Input.allCases.filter(\.isBindable), id: \.self) { input in
        let key = state.keymap[input]
        let isUnique = key == nil ? true : state.keymap.values.filter({ $0 == key }).count == 1
        let isBound = state.keymap[input] != nil
        let isSelected = state.selectedInput == input

        let labelColor = Self.labelColor(isUnique: isUnique, isBound: isBound, isSelected: isSelected)

        HStack {
          // Input name (e.g. 'Sneak')
          Text(input.humanReadableLabel)
            .frame(width: 150)

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
              .foregroundColor(labelColor)
          })
          .buttonStyle(SecondaryButtonStyle())

          // Button to unbind an input
          IconButton("xmark", isDisabled: !isBound || isSelected) {
            state.keymap.removeValue(forKey: input)
            managedConfig.keymap.bindings = state.keymap
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
