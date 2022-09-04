import Collections

/// Storage for a game's chat.
public struct Chat {
  public static let maximumScrollback = 200

  /// All messages sent and received.
  public var messages: Deque<ChatMessage> = []

  /// Creates an empty chat.
  public init() {}

  /// Add a message to the chat.
  /// - Parameter message: The message to add.
  public mutating func add(_ message: ChatMessage) {
    messages.append(message)
    if messages.count > Self.maximumScrollback {
      messages.removeFirst()
    }
  }
}
