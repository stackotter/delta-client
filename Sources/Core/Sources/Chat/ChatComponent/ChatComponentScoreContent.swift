import Foundation

extension ChatComponent {
  /// The content of a score component.
  public struct ScoreContent: Codable, Equatable {
    /// The name of the user to display the score of. `*` indicates the current user.
    public var name: String
    /// The objective to display the score for.
    public var objective: String
    /// The score's value. If `nil`, the score value should be loaded from the world.
    public var value: String?
  }
}
