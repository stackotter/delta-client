import Foundation

public struct XSTSAuthenticationError: Codable {
  public let identity: String
  public let code: Int
  public let message: String
  public let redirect: String
  
  enum CodingKeys: String, CodingKey {
    case identity = "Identity"
    case code = "XErr"
    case message = "Message"
    case redirect = "Redirect"
  }
}
