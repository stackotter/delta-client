import Foundation

public protocol Account: Codable {
  var id: String { get set }
  var profileId: String { get set }
  var username: String { get set }
}

extension Account {
  public var type: String {
    switch self {
      case _ as MojangAccount:
        return "Mojang"
      case _ as OfflineAccount:
        return "Offline"
      default:
        return "Unknown"
    }
  }
}
