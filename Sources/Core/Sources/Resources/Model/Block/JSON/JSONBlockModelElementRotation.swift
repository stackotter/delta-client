import Foundation

/// The rotation of a block model element as read from a Mojang formatted block model file.
struct JSONBlockModelElementRotation: Codable {
  /// The point to rotate around.
  var origin: [Double]
  /// The axis of the rotation.
  var axis: JSONBlockModelAxis
  /// The angle of the rotaiton.
  var angle: Double
  /// Whether to scale block to fit original space after rotation or not, if nil assume false.
  var rescale: Bool?
}
