import Foundation

struct MojangAuthenticationResponse: Decodable {
  struct MojangUser: Codable {
    var id: String
    var username: String
  }
  
  struct MojangProfile: Codable {
    var name: String
    var id: String
  }
  
  var user: MojangUser
  var clientToken: String
  var accessToken: String
  var selectedProfile: MojangProfile
  var availableProfiles: [MojangProfile]
}
