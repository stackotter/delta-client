//
//  PixlyzerBlockModelDescriptor.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import simd

public struct PixlyzerBlockModelDescriptor: Decodable {
  var model: Identifier
  /// The x rotation to apply in degrees.
  var xRotation: Int?
  /// The y rotation to apply in degrees.
  var yRotation: Int?
  var uvLock: Bool?
  
  enum CodingKeys: String, CodingKey {
    case model
    case xRotation = "x"
    case yRotation = "y"
    case uvLock = "uvlock"
  }
}
