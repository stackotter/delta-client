import SwiftUI
import DeltaCore

class KeymapEditorState: ObservableObject {
  @Published var keymap: [Input: Key]
  @Published var selectedInput: Input?

  init(keymap: [Input: Key]) {
    self.keymap = keymap
    selectedInput = nil
  }
}
