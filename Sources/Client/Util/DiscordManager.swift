import Foundation
import SwordRPC

// MARK: - RichPresence


/// Discord RichPresence presets
enum RichPreset: Equatable {
  case menu
  /// Associated value to be generally used to display game server ip address
  case game(String?)
  
  /// Rich presence detail
  fileprivate var title: String {
    switch self {
      case .menu: return "Main menu"
      case .game: return "In game"
    }
  }
  /// Rich presence state
  fileprivate var subtitle: String? {
    switch self {
      case .game(let address): return address
      default: return nil
    }
  }
}


// MARK: - DiscordManager


/// Manages discord interactions
class DiscordManager {
  // MARK: - Properties.static
  
  
  /// `DiscordManager` shared instance
  public static let shared = DiscordManager()
  
  
  // MARK: - Properties.private
  
  
  /// The discord rich presence currently being displayed on the user's profile
  private var currentRichPresence: RichPreset?
  
  
  // MARK: - Properties.managers
  
  
  /// Manages discord rich presence
  private let richPresenceManager = SwordRPC(appId: "907736809990148107")
  
  
  // MARK: - Inits
  
  
  private init() {
    let _ = richPresenceManager.connect()
  }
  
  
  // MARK: - Methods.public
  
  
  /// Updates user's discord rich presence
  ///
  /// - Parameter preset: the preset to be used to configure the rich presence
  public func updateRichPresence(with preset: RichPreset) {
    // If a menu update is asked twice in a row, doing nothing as that would simply result in the rich presence timestamp being wrongfully reset
    if currentRichPresence == .menu && preset == .menu { return }
    
    var presence = RichPresence()
    presence.assets.largeImage = "dark"
    presence.details = preset.title
    presence.state = preset.subtitle
    presence.timestamps.start = Date()
    richPresenceManager.setPresence(presence)
    currentRichPresence = preset
  }
}


