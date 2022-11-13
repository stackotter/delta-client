public struct ChatMessageReceivedEvent: Event {
  public var message: ChatMessage

  public init(_ message: ChatMessage) {
    self.message = message
  }
}
