import Foundation

struct MicrosoftAccessTokenResponse: Decodable {
  var tokenType: String
  var expiresIn: Int
  var scope: String
  var accessToken: String
  var refreshToken: String

  enum CodingKeys: String, CodingKey {
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
  }
}
