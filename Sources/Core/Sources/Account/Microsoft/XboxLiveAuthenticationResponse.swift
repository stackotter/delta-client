import Foundation

struct XboxLiveAuthenticationResponse: Codable {
  public struct Claims: Codable {
    public var xui: [XUIClaim]
  }
  
  public struct XUIClaim: Codable {
    public var userHash: String
    
    // swiftlint:disable nesting
    private enum CodingKeys: String, CodingKey {
      case userHash = "uhs"
    }
    // swiftlint:enable nesting
  }
  
  public var issueInstant: String
  public var notAfter: String
  public var token: String
  public var displayClaims: Claims
  
  private enum CodingKeys: String, CodingKey {
    case issueInstant = "IssueInstant"
    case notAfter = "NotAfter"
    case token = "Token"
    case displayClaims = "DisplayClaims"
  }
}
