import Foundation

struct XSTSAuthenticationResponse: Codable {
  struct Claims: Codable {
    var xui: [XUIClaim]
  }
  
  struct XUIClaim: Codable {
    var userHash: String
    
    private enum CodingKeys: String, CodingKey {
      case userHash = "uhs"
    }
  }
  
  var issueInstant: String
  var notAfter: String
  var token: String
  var displayClaims: Claims
  
  enum CodingKeys: String, CodingKey {
    case issueInstant = "IssueInstant"
    case notAfter = "NotAfter"
    case token = "Token"
    case displayClaims = "DisplayClaims"
  }
}
