import SwiftUI

struct ControlsView: View {
  var body: some View {
    InputView { inputCaptured, delegateSetter in
      ControlsEditorView(
        inputCaptured: inputCaptured,
        inputDelegateSetter: delegateSetter)
    }
  }
}
