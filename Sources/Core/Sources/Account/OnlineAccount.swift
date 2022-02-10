public protocol OnlineAccount {
  var id: String { get }
  var username: String { get }
  var accessToken: MinecraftAccessToken { get }
}
