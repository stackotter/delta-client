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

  public var isChatOpen: Bool {
    return messageInput != nil
  }

  public init() {}
}
