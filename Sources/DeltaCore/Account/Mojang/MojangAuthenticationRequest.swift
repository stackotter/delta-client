import Foundation

struct MojangAuthenticationRequest: Encodable {
  var agent: MojangAgent
  var username: String
  var password: String
  var clientToken: String
  var requestUser: Bool
}
