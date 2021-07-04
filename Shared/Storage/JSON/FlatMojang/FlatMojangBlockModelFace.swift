//
//  FlatMojangBlockModelFace.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// Flattened mojang block model face format.
public struct FlatMojangBlockModelFace {
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
  /// The index of the tint to use.
  public var tintIndex: Int
  
  /// Returns a neater and flattened version of a Mojang formatted block model face.
  public init(
    from mojangFace: MojangBlockModelFace,
    facing mojangDirection: MojangBlockModelFaceName,
    with textureVariables: [String: String]
  ) {
    uv = mojangFace.uv
    direction = mojangDirection.direction
    cullface = mojangFace.cullface?.direction
    tintIndex = mojangFace.tintIndex ?? -1
    
    // Substitute in a texture variable if a relevant one is present
    if mojangFace.texture.starts(with: "#") {
      // A texture variable always starts with a hashtag
      let textureVariable = mojangFace.texture
      // Get rid of the hashtag
      let textureVariableName = String(textureVariable.dropFirst(1))
      // If there is a substitution for this variable use it instead, otherwise keep the variable
      texture = textureVariables[textureVariableName] ?? textureVariable
    } else {
      // The texture is an identifier already and nothing needs to be done.
      texture = mojangFace.texture
    }
    
    // Round textureRotation to the nearest 90
    textureRotation = mojangFace.rotation ?? 0
    textureRotation -= textureRotation % 90
  }
}
