public struct GUIState {
  // TODO: Figure out why anything greater than 252 breaks the protocol. Anything less than 256 should work afaict
  public static let maximumMessageLength = 252

  public var showDebugScreen = false
  public var showInventory = false
  public var chat = Chat()
  public var messageInput: String?
  public var stashedMessageInput: String?
  public var playerMessageHistory: [String] = []
  public var currentMessageIndex: Int?
  /// The cursor position in the message input. 0 is the end of the message, and the maximum value is the beginning of the message.
  public var messageInputCursor: Int = 0
  public var messageInputCursorIndex: String.Index {
    if let messageInput = messageInput {
      return messageInput.index(messageInput.endIndex, offsetBy: -messageInputCursor)
    } else {
      return "".endIndex
    }
  }

  public var isChatOpen: Bool {
    return messageInput != nil
  }

  public init() {}
}
