import SwiftUI
import DeltaCore

class ControlsState: ObservableObject {
  @Published var keyMapping: [Input: Key]
  @Published var selectedInput: Input?
  
  init(keyMapping: [Input: Key]) {
    self.keyMapping = keyMapping
    selectedInput = nil
  }
}
