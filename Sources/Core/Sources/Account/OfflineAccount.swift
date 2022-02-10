import Foundation

/// A user account that can only connect to offline mode servers.
public struct OfflineAccount: Codable {
  public var id: String
  public var username: String
  
  public init(username: String) {
    self.username = username
    
    let generatedUUID = UUID.fromString("OfflinePlayer: \(username)")?.uuidString
    id = generatedUUID ?? UUID().uuidString
  }
}
