import Foundation
import simd

/// Flattened mojang block model face format.
public struct IntermediateBlockModelFace {
  /// The direction the face should face before transformations are applied.
  /// This won't always be the direction the face ends up facing.
  public var direction: Direction
  /// Face texture uv coordinates (if they're not present we have to make them up).
  public var uv: [Double]?
  /// The identifier of the texture to use for this face.
  public var texture: String
  /// The direction that a culling block must be in for this face not to be rendered.
  public var cullface: Direction?
  /// The amount of rotation for the texture (multiples of 90 degrees).
  public var textureRotation: Int
  /// Whether a tint color should be applied to the face or not.
  public var isTinted: Bool
  
  /// Returns a neater and flattened version of a Mojang formatted block model face.
  public init(
    from jsonFace: JSONBlockModelFace,
    facing jsonDirection: JSONBlockModelFaceName,
    with textureVariables: [String: String]
  ) {
    uv = jsonFace.uv
    direction = jsonDirection.direction
    cullface = jsonFace.cullface?.direction
    isTinted = (jsonFace.tintIndex ?? -1) != -1
    
    // Round textureRotation to the nearest 90
    textureRotation = jsonFace.rotation ?? 0
    textureRotation -= textureRotation % 90
    
    texture = jsonFace.texture
    
    updateTexture(with: textureVariables)
  }
  
  /// Substitutes the texture of this face with a replacement from some texture variables if there is a valid replacement.
  public mutating func updateTexture(with textureVariables: [String: String]) {
    // Substitute in a texture variable if a relevant one is present
    if texture.starts(with: "#") {
      // A texture variable always starts with a hashtag
      let textureVariable = texture
      // Get rid of the hashtag
      let textureVariableName = String(textureVariable.dropFirst(1))
      // If there is a substitution for this variable use it instead, otherwise keep the variable
      texture = textureVariables[textureVariableName] ?? textureVariable
    }
  }
}
