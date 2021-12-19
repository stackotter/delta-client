import Foundation

struct MojangAgent: Codable {
  var name: String
  var version: Int
  
  init() {
    self.name = "Minecraft"
    self.version = 1
  }
}
