import Foundation

/// A user account that authenticates using the new Microsoft method.
public struct MicrosoftAccount: Codable, OnlineAccount, Hashable {
  /// The account's id as a uuid.
  public var id: String
  /// The account's username.
  public var username: String
  /// The access token used to connect to servers.
  public var accessToken: MinecraftAccessToken
  /// The Microsoft access token and refresh token pair.
  public var microsoftAccessToken: MicrosoftAccessToken
  
  /// Creates an account with the given properties.
  public init(
    id: String,
    username: String,
    minecraftAccessToken: MinecraftAccessToken,
    microsoftAccessToken: MicrosoftAccessToken
  ) {
    self.id = id
    self.username = username
    accessToken = minecraftAccessToken
    self.microsoftAccessToken = microsoftAccessToken
  }
}
