import SwiftUI
import DeltaCore

class KeyMappingEditorState: ObservableObject {
  @Published var keyMapping: [Input: Key]
  @Published var selectedInput: Input?
  
  init(keyMapping: [Input: Key]) {
    self.keyMapping = keyMapping
    selectedInput = nil
  }
}
