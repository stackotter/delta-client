import Foundation

/// Represents a comparison between GitHub branches and/or commits
struct GitHubComparison: Decodable {
  /// The position difference between the compared objects in the tree
  enum Status: String, Decodable {
    case diverged
    case ahead
    case behind
    case identical
  }
  
  var status: Status
}
