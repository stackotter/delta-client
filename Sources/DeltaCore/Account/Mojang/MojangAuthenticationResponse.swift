import Foundation

struct MojangAuthenticationResponse: Decodable {
  var user: MojangUser
  var clientToken: String
  var accessToken: String
  var selectedProfile: Profile
  var availableProfiles: [Profile]
}
