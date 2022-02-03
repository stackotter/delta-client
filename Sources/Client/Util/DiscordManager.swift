import Foundation
import SwordRPC

/// Manages discord interactions
final class DiscordManager {
  /// ``DiscordManager`` shared instance.
  public static let shared = DiscordManager()
  
  /// The discord rich presence currently being displayed on the user's profile.
  private var currentPresenceState: RichPresenceState?
  
  /// Manages discord rich presence.
  private let richPresenceManager = SwordRPC(appId: "907736809990148107")
  
  private init() {
    _ = richPresenceManager.connect()
  }
  
  /// Updates the user's discord rich presence state for Delta Client.
  /// - Parameter state: the preset to be used to configure the rich presence.
  public func updateRichPresence(to state: RichPresenceState) {
    guard currentPresenceState != state else {
      return
    }
    
    var presence = RichPresence()
    presence.assets.largeImage = "dark"
    presence.details = state.title
    presence.state = state.subtitle
    presence.timestamps.start = Date()
    richPresenceManager.setPresence(presence)
    currentPresenceState = state
  }
}


