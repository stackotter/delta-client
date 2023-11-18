import Foundation

/// A keymap stores the user's keybindings.
public struct Keymap {
  /// The client's default key bindings.
  public static var `default` = Keymap(bindings: [
    .place: .rightMouseButton,
    .destroy: .leftMouseButton,
    .moveForward: .w,
    .moveBackward: .s,
    .strafeLeft: .a,
    .strafeRight: .d,
    .jump: .space,
    .sneak: .leftShift,
    .sprint: .leftControl,
    .toggleHUD: .f1,
    .toggleDebugHUD: .f3,
    .toggleInventory: .e,
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
    .nextSlot: .scrollUp,
    .previousSlot: .scrollDown,
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

/// We implement `Codable` ourselves because the default codable works very strangely,
/// with keys that aren't strings or integers.
///
/// Here's a sample of what the default implementations do (wtf),
///
/// ```json
/// "bindings" : [
///   {
///     "moveForward" : {
///
///     }
///   },
///   {
///     "w" : {
///
///     }
///   },
///   {
///     "previousSlot" : {
///
///     }
///   },
///   {
///     "scrollDown" : {
///
///     }
///   },
///   ...
/// ]
/// ```
///
/// Each key value pair is actually just two consecutive objects in an array, with empty
/// payloads. Here's the format we implement ourselves,
/// 
/// ```json
/// "bindings": {
///   "moveForward": "w",
///   "previousSlot": "scrollDown"
/// }
/// ```
extension Keymap: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Input.self)

    bindings = [:]
    for input in container.allKeys {
      bindings[input] = try container.decode(Key.self, forKey: input)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Input.self)

    for (input, key) in bindings {
      try container.encode(key, forKey: input)
    }
  }
}

extension Input: CodingKey {
  public var stringValue: String {
    rawValue
  }

  public var intValue: Int? {
    nil
  }

  public init?(stringValue: String) {
    self.init(rawValue: stringValue)
  }

  public init?(intValue: Int) {
    return nil
  }
}
