import Foundation

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
    .slot1: .one,
    .slot2: .two,
    .slot3: .three,
    .slot4: .four,
    .slot5: .five,
    .slot6: .six,
    .slot7: .seven,
    .slot8: .eight,
    .slot9: .nine,
    .openChat: .t
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
