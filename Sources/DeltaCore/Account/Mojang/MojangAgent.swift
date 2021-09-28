import Foundation

struct MojangAgent: Codable {
  var name: String
  var version: Int
  
  init() {
    self.name = "Minecraft"
    self.version = 1
  }
  
  init(name: String, version: Int) {
    self.name = name
    self.version = version
  }
}
