import Foundation

struct GitHubReleasesAPIResponse: Codable {
  var tagName: String
  var assets: [Asset]
  
  struct Asset: Codable {
    var browserDownloadUrl: String
  }
}
