import Foundation

public struct MicrosoftAccessTokenResponse: Codable {
  public var tokenType: String
  public var expiresIn: Int
  public var scope: String
  public var accessToken: String
  public var refreshToken: String
  public var userId: String
  public var foci: String
  
  private enum CodingKeys: String, CodingKey {
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case userId = "user_id"
    case foci
  }
}
