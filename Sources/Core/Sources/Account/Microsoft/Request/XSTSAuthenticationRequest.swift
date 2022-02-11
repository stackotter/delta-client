import Foundation

struct XSTSAuthenticationRequest: Codable {
  struct Properties: Codable {
    var sandboxId: String
    var userTokens: [String]
    
    // swiftlint:disable nesting
    enum CodingKeys: String, CodingKey {
      case sandboxId = "SandboxId"
      case userTokens = "UserTokens"
    }
    // swiftlint:enable nesting
  }
  
  var properties: Properties
  var relyingParty: String
  var tokenType: String
  
  enum CodingKeys: String, CodingKey {
    case properties = "Properties"
    case relyingParty = "RelyingParty"
    case tokenType = "TokenType"
  }
}
