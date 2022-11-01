import Foundation

/// A descriptor describing transformations to apply to a model from a resource pack. When rendering it for a specific block state.
public struct PixlyzerBlockModelDescriptor: Decodable {
  /// The block model identifier used to find the model in resource packs.
  var model: Identifier
  /// The x rotation to apply in degrees.
  var xRotation: Int?
  /// The y rotation to apply in degrees.
  var yRotation: Int?
  /// Whether to rotate the textures with the model or not.
  var uvLock: Bool?

  enum CodingKeys: String, CodingKey {
    case model
    case xRotation = "x"
    case yRotation = "y"
    case uvLock = "uvlock"
  }
}

extension BlockModelRenderDescriptor {
  public init(from pixlyzerDescriptor: PixlyzerBlockModelDescriptor) {
    self.init(
      model: pixlyzerDescriptor.model,
      xRotationDegrees: pixlyzerDescriptor.xRotation ?? 0,
      yRotationDegrees: pixlyzerDescriptor.yRotation ?? 0,
      uvLock: pixlyzerDescriptor.uvLock ?? false)
  }
}
