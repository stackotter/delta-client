extension LegacyFormattedText {
  /// A formatted text token.
  public struct Token: Equatable {
    let string: String
    let color: Color?
    let style: Style?
  }
}
