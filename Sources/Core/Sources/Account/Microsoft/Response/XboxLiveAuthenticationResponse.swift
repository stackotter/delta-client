import Foundation

struct XboxLiveAuthenticationResponse: Codable {
  struct Claims: Codable {
    var xui: [XUIClaim]
  }
  
  struct XUIClaim: Codable {
    var userHash: String
    
    // swiftlint:disable nesting
    enum CodingKeys: String, CodingKey {
      case userHash = "uhs"
    }
    // swiftlint:enable nesting
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
