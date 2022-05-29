extension ChatComponent {
  /// The content of a localized component.
  public struct LocalizedContent: Equatable {
    /// The identifier of the localized template to use.
    public var translateKey: String
    /// Content to replace placeholders in the localized template with.
    public var content: [ChatComponent]
  }
}
