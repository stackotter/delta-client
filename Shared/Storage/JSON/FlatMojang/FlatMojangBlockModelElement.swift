//
//  FlatMojangBlockModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
import simd

// i am currently fixing uv coordinate generation, that is the last major thing that has to be done with block model reading.
// it might be easiest to just use default parameters for now and wait until rendering is working again to actually get them working (might be a bit of trial and error knowing mojang)

/// Flattened mojang block model element format.
public struct FlatMojangBlockModelElement {
  /// The minimum vertex of the element. For a dirt block this would be (0, 0, 0).
  public var from: simd_float3
  /// The maximum vertex of the element. For a dirt block this would be (1, 1, 1).
  public var to: simd_float3
  /// The rotation matrix for this block model.
  public var rotation: FlatMojangBlockModelElementRotation?
  /// Whether to render shadows or not.
  public var shade: Bool
  /// The faces present on this element.
  public var faces: [FlatMojangBlockModelFace]
  
  /// Creates a neater and flattened version of a Mojang formatted block model.
  init(from mojangElement: MojangBlockModelElement, with textureVariables: [String: String]) throws {
    let blockSize: Float = 16
    
    // Convert the arrays of doubles to vectors and scale so that they are the same scale as world space
    let from = try MathUtil.vectorFloat3(from: mojangElement.from) / blockSize
    let to = try MathUtil.vectorFloat3(from: mojangElement.to) / blockSize
    
    // I don't trust mojang so this makes sure from and to are actually the minimum and maximum vertices of the element
    self.from = min(from, to)
    self.to = max(from, to)
    
    if let mojangRotation = mojangElement.rotation {
      rotation = try FlatMojangBlockModelElementRotation(from: mojangRotation)
    }
    
    shade = mojangElement.shade ?? true
    
    faces = mojangElement.faces.map { (mojangDirection, mojangFace) in
      FlatMojangBlockModelFace(
        from: mojangFace,
        facing: mojangDirection,
        with: textureVariables)
    }
  }
  
  /// The transformation matrix to apply to a 1x1x1 cube to get this element.
  var transformationMatrix: matrix_float4x4 {
    let scale = to - from
    var matrix = MatrixUtil.scalingMatrix(scale)
    matrix *= MatrixUtil.translationMatrix(from)
    if let rotation = rotation {
      matrix *= rotation.matrix
    }
    
    return matrix
  }
  
  /// Returns which directions this block has full faces in.
  public func getCullingFaces() -> Set<Direction> {
    // There cannot be a full face if the element has rotation not a multiple of 90 degrees.
    // The only possible multiple of 90 degrees is 0 in this case
    if (rotation?.degrees ?? 0) != 0 {
      return []
    }
    
    // Since rotation is 0 we can just ignore it now.
    var cullFaces: Set<Direction> = []
    
    // Checking north, down and west faces (negative directions)
    if from == simd_float3(repeating: 0) {
      if to.x == 1 && to.y == 1 {
        cullFaces.insert(.north)
      }
      if to.x == 1 && to.z == 1 {
        cullFaces.insert(.down)
      }
      if to.y == 1 && to.z == 1 {
        cullFaces.insert(.west)
      }
    }
    
    // Checking south, up and east faces (positive directions)
    if to == simd_float3(repeating: 1) {
      if from.x == 0 && from.y == 0 {
        cullFaces.insert(.south)
      }
      if from.x == 0 && from.z == 0 {
        cullFaces.insert(.up)
      }
      if from.y == 0 && from.z == 0 {
        cullFaces.insert(.east)
      }
    }
    
    return cullFaces
  }
}
