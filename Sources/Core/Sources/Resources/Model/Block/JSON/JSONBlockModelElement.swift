import Foundation

/// A block model element as read from a Mojang formatted block model file.
struct JSONBlockModelElement: Codable {
  /// The starting point of the element.
  var from: [Double]
  /// The finishing point of the element.
  var to: [Double]
  /// The rotation of the element.
  var rotation: JSONBlockModelElementRotation?
  /// Whether to render shadows or not, if nil assume true.
  var shade: Bool?
  /// The present faces of the element. The keys are face direction and should be one of;
  /// `down`, `up`, `north`, `south`, `west` or `east`
  var faces: [String: JSONBlockModelFace]
}
