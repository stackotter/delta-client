import Foundation

/// A conditional replacement of an item model with another. Used for items such as compasses and
/// clocks (which change depending on heading and time respectively).
struct JSONItemModelOverride: Decodable {
  /// Conditions to be met.
  var predicate: [String: Float]
  /// Replacement model.
  var model: Identifier
}
