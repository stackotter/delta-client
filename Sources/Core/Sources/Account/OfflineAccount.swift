import Foundation

/// A user account that can only connect to offline mode servers.
public struct OfflineAccount: Codable, Hashable {
  public var id: String
  public var username: String
  
  /// Creates an offline account.
  ///
  /// The account's UUID is generated based on the username.
  /// - Parameter username: The username for the account.
  public init(username: String) {
    self.username = username
    
    let generatedUUID = UUID.fromString("OfflinePlayer: \(username)")?.uuidString
    id = generatedUUID ?? UUID().uuidString
  }
}
