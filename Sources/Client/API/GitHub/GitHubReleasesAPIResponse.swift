import Foundation

struct GitHubReleasesAPIResponse: Codable {
  var tagName: String
  var assets: [Asset]
  
  struct Asset: Codable {
    var browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
      case browserDownloadURL = "browserDownloadUrl"
    }
  }
}
