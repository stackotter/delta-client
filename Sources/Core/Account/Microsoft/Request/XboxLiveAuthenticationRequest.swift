import Foundation

struct XboxLiveAuthenticationRequest: Codable {
  struct Properties: Codable {
    var authMethod: String
    var siteName: String
    var accessToken: String
    
    // swiftlint:disable nesting
    enum CodingKeys: String, CodingKey {
      case authMethod = "AuthMethod"
      case siteName = "SiteName"
      case accessToken = "RpsTicket"
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
