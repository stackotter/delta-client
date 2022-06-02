import Foundation

struct GameOwnershipResponse: Codable {
  struct License: Codable {
    var name: String
    var signature: String
  }
  
  var items: [License]
  var signature: String
  var keyId: String
}
