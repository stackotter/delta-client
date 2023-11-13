import Foundation

/// A user account that authenticates using the old Mojang method.
public struct MojangAccount: Codable, OnlineAccount, Hashable {
  public var id: String
  public var username: String
  public var accessToken: MinecraftAccessToken
  
  public init(
    id: String,
    username: String,
    accessToken: MinecraftAccessToken
  ) {
    self.id = id
    self.username = username
    self.accessToken = accessToken
  }
}
