import Foundation

struct GitHubBranch: Decodable {
  var name: String
  var commit: GitHubCommit
}
