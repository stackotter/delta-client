//
//  MojangBlockModelElementRotation.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

/// The rotation of a block model element as read from a Mojang formatted block model file.
public struct MojangBlockModelElementRotation: Codable {
  /// The point to rotate around.
  var origin: [Double]
  /// The axis of the rotation.
  var axis: MojangBlockModelAxis
  /// The angle of the rotaiton.
  var angle: Double
  /// Whether to scale block to fit original space after rotation or not, if nil assume false.
  var rescale: Bool?
}
