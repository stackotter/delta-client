import Foundation

struct MojangRefreshTokenRequest: Codable {
  var accessToken: String
  var clientToken: String
}
