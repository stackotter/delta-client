import Foundation

/// Manages discord interactions
final class DiscordManager {
  /// ``DiscordManager`` shared instance.
  public static let shared = DiscordManager()
  
  /// The discord rich presence currently being displayed on the user's profile.
  private var currentPresenceState: RichPresenceState?
  
  /// Manages discord rich presence.
  
  private init() {
  }
  
  /// Updates the user's discord rich presence state for Delta Client.
  /// - Parameter state: the preset to be used to configure the rich presence.
  public func updateRichPresence(to state: RichPresenceState) {
  }
}
