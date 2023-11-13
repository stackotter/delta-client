import Foundation

#if os(macOS)
import SwordRPC
#endif

/// Manages discord interactions
final class DiscordManager {
  /// ``DiscordManager`` shared instance.
  public static let shared = DiscordManager()
  
  /// The discord rich presence currently being displayed on the user's profile.
  private var currentPresenceState: RichPresenceState?
  
  #if os(macOS)
  /// Manages discord rich presence.
  private let richPresenceManager = SwordRPC(appId: "907736809990148107")
  #endif
  
  private init() {
    #if os(macOS)
    _ = richPresenceManager.connect()
    #endif
  }
  
  /// Updates the user's discord rich presence state for Delta Client if the current OS is supported.
  /// - Parameter state: the preset to be used to configure the rich presence.
  public func updateRichPresence(to state: RichPresenceState) {
    #if os(macOS)
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
    #endif
  }
}
