import Foundation

struct MicrosoftMinecraftProfileResponse: Decodable {
  var id: String
  var name: String
  var skins: [Skin]
  var capes: [Cape]?
  
  struct Skin: Decodable {
    var id: String
    var state: String
    var url: URL
    var variant: String
    var alias: String?
  }
  
  struct Cape: Decodable {
    var id: String
    var state: String
    var url: URL
    var alias: String?
  }
}
