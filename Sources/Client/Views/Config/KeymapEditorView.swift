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
      ForEach(Input.allCases, id: \.self) { input in
        let key = state.keymap[input]
        let isUnique = key == nil ? true : state.keymap.values.filter({ $0 == key }).count == 1
        let isBound = state.keymap[input] != nil
        let isSelected = state.selectedInput == input
        let keyName = key?.rawValue ?? "Unbound"
        let labelColor = Self.labelColor(isUnique: isUnique, isBound: isBound, isSelected: isSelected)
        let unboundable = isBound && !isSelected
        
        HStack {
          HStack {
            // Input name
            Text(input.humanReadableLabel)
              .font(Font.custom(.worksans, size: 15))
              .foregroundColor(.white)
            Spacer()
            // Input button
            Text(isSelected ? "> Press key <" : keyName)
              .font(Font.custom(.worksans, size: 14))
              .foregroundColor(labelColor)
              .frame(width: 150, height: 30)
              .background(Color.lightGray)
              .cornerRadius(4)
              .contentShape(Rectangle())
              .onTapGesture {
                inputCaptured = !isSelected
                state.selectedInput = isSelected ? nil : input
              }
          }
          .frame(width: 400)
          // Remove input button
          if unboundable {
            Button {  } label: {
              Image(systemName: "trash")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .offset(x: unboundable ? -4 : -15)
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
