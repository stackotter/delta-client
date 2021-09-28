//
//  BlockModelElement.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import simd

/// A block model element is a rectangular prism. All block models are built from elements.
public struct BlockModelElement {
  /// First of two vertices defining this rectangular prism.
  public var transformation: matrix_float4x4
  /// Whether to render shadows or not.
  public var shade: Bool
  /// The faces present on this element.
  public var faces: [BlockModelFace]
  
  public init(transformation: matrix_float4x4, shade: Bool, faces: [BlockModelFace]) {
    self.transformation = transformation
    self.shade = shade
    self.faces = faces
  }
}
