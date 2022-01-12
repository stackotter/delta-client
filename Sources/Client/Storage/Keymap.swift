import Foundation
import DeltaCore

/// A keymap stores the user's keybindings.
struct Keymap: Codable {
  /// The client's default key bindings.
  static var `default` = Keymap(bindings: [
    .moveForward: .w,
    .moveBackward: .s,
    .strafeLeft: .a,
    .strafeRight: .d,
    .jump: .space,
    .sneak: .leftShift,
    .sprint: .leftControl,
    .toggleDebugHUD: .f3
  ])
  
  /// The user's keybindings.
  var bindings: [Input: Key]
  
  /// Creates a new keymap.
  /// - Parameter bindings: Bindings for the new keymap.
  init(bindings: [Input : Key]) {
    self.bindings = bindings
  }
  
  /// - Returns: The input action for the given key if bound.
  func getInput(for key: Key) -> Input? {
    for (input, inputKey) in bindings {
      if key == inputKey {
        return input
      }
    }
    return nil
  }
}
