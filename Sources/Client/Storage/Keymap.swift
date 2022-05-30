import Foundation
import DeltaCore

/// A keymap stores the user's keybindings.
public struct Keymap: Codable {
  /// The client's default key bindings.
  public static var `default` = Keymap(bindings: [
    .moveForward: .w,
    .moveBackward: .s,
    .strafeLeft: .a,
    .strafeRight: .d,
    .jump: .space,
    .sneak: .leftShift,
    .sprint: .leftControl,
    .toggleDebugHUD: .f3,
    .changePerspective: .f5,
    .performGPUFrameCapture: .semicolon
  ])
  
  /// The user's keybindings.
  public var bindings: [Input: Key]
  
  /// Creates a new keymap.
  /// - Parameter bindings: Bindings for the new keymap.
  init(bindings: [Input: Key]) {
    self.bindings = bindings
  }
  
  /// - Returns: The input action for the given key if bound.
  public func getInput(for key: Key) -> Input? {
    for (input, inputKey) in bindings where key == inputKey {
      return input
    }
    return nil
  }
}
