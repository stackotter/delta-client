import Foundation
import DeltaCore

/// A keymap stores the user's keybindings.
public struct Keymap: Codable {
  /// The user's keybindings.
  public var bindings: [Input: Key]
  
  /// Creates a new keymap.
  /// - Parameter bindings: Bindings for the new keymap.
  init(bindings: [Input : Key]) {
    self.bindings = bindings
  }
  
  public func getInput(for key: Key) -> Input? {
    for (input, inputKey) in bindings {
      if key == inputKey {
        return input
      }
    }
    return nil
  }
}
