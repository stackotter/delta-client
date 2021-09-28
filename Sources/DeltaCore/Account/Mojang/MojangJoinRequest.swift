import Foundation

struct MojangJoinRequest: Codable {
  var accessToken: String
  var selectedProfile: String
  var serverId: String
}
