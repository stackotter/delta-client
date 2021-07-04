//
//  MojangBlockModelFace.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// A block model element's face as read from a Mojang formatted block model file.
public struct MojangBlockModelFace: Codable {
  /// The texture uv coordinates of the face. Should be in the form `[u1, v1, u2, v2]`.
  /// If nil the uv coordinates are calculated from the face's position in the block.
  var uv: [Double]?
  /// The identifier or texture variable representing the texture this face uses.
  var texture: String
  /// The direction a culling block must be in for this face not to be rendered.
  var cullface: MojangBlockModelFaceName?
  /// The amount to rotate the face's texture. Should be a multiple of 90 degrees.
  var rotation: Int?
  /// The index of the tint to use. I'm not exactly sure how this is used yet.
  var tintIndex: Int?
}
