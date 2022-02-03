import Foundation

struct GitHubArtifactsAPIResponse: Codable {
  var artifacts: [Artifact]
  
  struct Artifact: Codable {
    var id: Int
    var expired: Bool
  }
}
