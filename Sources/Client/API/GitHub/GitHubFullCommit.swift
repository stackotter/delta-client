import Foundation

struct GitHubFullCommit: Decodable {
  struct Commit: Decodable {
    struct Committer: Decodable {
      var date: String
    }
    var committer: Committer
  }
  var commit: Commit
}