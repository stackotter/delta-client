import Foundation

extension DiscordManager {
  /// State of Discord rich presence.
  enum RichPresenceState: Equatable {
    /// The user is not currently connected to a server.
    case menu
    /// The user is playing on a server.
    case game(server:String?)
    
    /// Shown as the state of the game in Discord. Displayed under the name 'Delta Client'.
    var title: String {
      switch self {
        case .menu:
          return "Main menu"
        case .game:
          return "In game"
      }
    }
    
    /// Shown under `title` by Discord.
    var subtitle: String? {
      switch self {
        case .menu:
          return nil
        case .game(let server):
          if let server = server {
            return "Playing on '\(server)'"
          }
          return nil
      }
    }
  }
}
