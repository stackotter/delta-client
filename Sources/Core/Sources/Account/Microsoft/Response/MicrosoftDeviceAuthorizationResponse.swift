import Foundation

public struct MicrosoftDeviceAuthorizationResponse: Decodable {
  public var deviceCode: String
  public var userCode: String
  public var verificationURI: URL
  public var expiresIn: Int
  public var interval: Int
  public var message: String

  private enum CodingKeys: String, CodingKey {
    case deviceCode = "device_code"
    case userCode = "user_code"
    case verificationURI = "verification_uri"
    case expiresIn = "expires_in"
    case interval
    case message = "message"
  }
}
