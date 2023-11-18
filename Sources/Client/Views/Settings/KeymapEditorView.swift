import SwiftUI
import DeltaCore

struct KeymapEditorView: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  /// Whether key inputs are being captured by the view.
  @State var inputCaptured = false
  /// The input currently selected for rebinding.
  @State var selectedInput: Input?

  var body: some View {
    InputView(listening: $inputCaptured, cursorCaptured: false) {
      ForEach(Input.allCases.filter(\.isBindable), id: \.self) { (input: Input) in
        let bindings = managedConfig.keymap.bindings
        let key = bindings[input]
        let isUnique = key == nil ? true : bindings.values.filter({ $0 == key }).count == 1
        let isBound = bindings[input] != nil
        let isSelected = selectedInput == input

        let labelColor = Self.labelColor(isUnique: isUnique, isBound: isBound, isSelected: isSelected)

        HStack {
          // Input name (e.g. 'Sneak')
          Text(input.humanReadableLabel)
            .frame(width: 150)

          // Button to set a new binding
          let keyName = bindings[input]?.description ?? "Unbound"
          Button(action: {
            if isSelected {
              managedConfig.keymap.bindings[input] = .leftMouseButton
              selectedInput = nil
              inputCaptured = false
            } else {
              selectedInput = input
              inputCaptured = true
            }
          }, label: {
            Text(isSelected ? "> Press key <" : keyName)
              .foregroundColor(labelColor)
          })
          .buttonStyle(SecondaryButtonStyle())
          .disabled(isSelected)

          // Button to unbind an input
          IconButton("xmark", isDisabled: !isBound || isSelected) {
            managedConfig.keymap.bindings.removeValue(forKey: input)
          }
        }
        .frame(width: 400)
      }
    }
    .passthroughClicks()
    .onKeyPress { key, _ in
      guard let selectedInput = selectedInput else {
        return
      }

      if key == .escape {
        managedConfig.keymap.bindings.removeValue(forKey: selectedInput)
      } else {
        managedConfig.keymap.bindings[selectedInput] = key
      }

      self.selectedInput = nil
    }
    .onKeyRelease { key in
      inputCaptured = false
    }

    Button("Reset bindings to defaults") {
      managedConfig.keymap.bindings = Keymap.default.bindings
    }
    .buttonStyle(SecondaryButtonStyle())
    .frame(width: 250)
    .padding(.top, 10)
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
