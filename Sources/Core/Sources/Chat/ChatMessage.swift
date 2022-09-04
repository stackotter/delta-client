import Foundation

/// A chat message.
public struct ChatMessage {
  /// The content of the message.
  public var content: ChatComponent
  /// The uuid of the message's sender.
  public var sender: UUID
  /// The time at which the message was received.
  public var timeReceived: CFAbsoluteTime

  /// Creates a new chat message.
  /// - Parameters:
  ///   - content: The message of the message (includes `<sender>` when received from
  ///     vanilla server).
  ///   - sender: The uuid of the message's sender.
  ///   - timeReceived: The time at which the message was received. Defaults to the current time.
  public init(
    content: ChatComponent,
    sender: UUID,
    timeReceived: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
  ) {
    self.content = content
    self.sender = sender
    self.timeReceived = timeReceived
  }
}
