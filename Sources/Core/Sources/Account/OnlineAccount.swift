/// An account that can be used to join online servers.
public protocol OnlineAccount {
  /// The account id (a UUID).
  var id: String { get }
  /// The username.
  var username: String { get }
  /// The access token for joining servers.
  var accessToken: MinecraftAccessToken { get }
}
