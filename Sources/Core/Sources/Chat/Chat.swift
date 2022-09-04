/// Storage for a game's chat.
public struct Chat {
  /// All messages sent and received.
  public var messages: [ChatMessage] = [] // TODO: limit size of scrollback buffer

  /// Creates an empty chat.
  public init() {}

  /// Add a message to the chat.
  /// - Parameter message: The message to add.
  public mutating func add(_ message: ChatMessage) {
    self.messages.append(message)
  }
}
