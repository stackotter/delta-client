import Foundation

struct MojangAuthenticationRequest: Encodable {
  struct MojangAgent: Codable {
    var name = "Minecraft"
    var version = 1
  }
  
  var agent = MojangAgent()
  var username: String
  var password: String
  var clientToken: String
  var requestUser: Bool
}
