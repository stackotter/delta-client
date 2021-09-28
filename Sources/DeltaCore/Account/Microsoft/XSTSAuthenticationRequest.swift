import Foundation

public struct XSTSAuthenticationRequest: Codable {
  public struct Properties: Codable {
    public var sandboxId: String
    public var userTokens: [String]
    
    // swiftlint:disable nesting
    private enum CodingKeys: String, CodingKey {
      case sandboxId = "SandboxId"
      case userTokens = "UserTokens"
    }
    // swiftlint:enable nesting
  }
  
  public var properties: Properties
  public var relyingParty: String
  public var tokenType: String
  
  private enum CodingKeys: String, CodingKey {
    case properties = "Properties"
    case relyingParty = "RelyingParty"
    case tokenType = "TokenType"
  }
}
