extension ChatComponent {
  /// The content of a chat component.
  public enum Content: Equatable {
    case string(String)
    case keybind(String)
    case score(ScoreContent)
    case translation(LocalizedContent)

    /// Converts the content to plain text.
    /// - Parameter locale: The locale to use when resolving localized content.
    /// - Returns: The content as plain text.
    public func toText(with locale: MinecraftLocale) -> String {
      switch self {
        case .string(let string):
          return string
        case .keybind(let keybind):
          // TODO: read the keybind's value from configuration
          return keybind
        case .score(let score):
          // TODO: load score value in `score.value` is nil
          return "\(score.name):\(score.objective):\(score.value ?? "unknown_value")"
        case .translation(let localizedContent):
          return locale.getTranslation(for: localizedContent.translateKey, with: localizedContent.content.map { component in
            return component.toText(with: locale)
          })
      }
    }
  }
}
