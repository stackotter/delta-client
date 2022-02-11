import Foundation

public struct XSTSAuthenticationError: Codable {
  public var identity: String
  public var code: Int
  public var message: String
  public var redirect: String
  
  enum CodingKeys: String, CodingKey {
    case identity = "Identity"
    case code = "XErr"
    case message = "Message"
    case redirect = "Redirect"
  }
}
