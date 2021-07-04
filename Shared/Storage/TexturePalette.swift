//
//  TexturePalette.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

/// A palette holding textures corresponding to identifiers.
public struct TexturePalette {
  /// A dictionary mapping texture identifier to texture index
  public var identifierToIndex: [Identifier: Int]
  /// All of the textures in the palette. Indexed by `identifierToIndex`.
  public var textures: [CGImage]
  
  /// Returns the texture refered to by the given identifier if present.
  public func textureIndex(for identifier: Identifier) -> Int? {
    return identifierToIndex[identifier]
  }
}
