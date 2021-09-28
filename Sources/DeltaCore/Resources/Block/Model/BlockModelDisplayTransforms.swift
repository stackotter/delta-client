//
//  BlockModelDisplayTransforms.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import simd

public struct BlockModelDisplayTransforms {
  /// Transform to use for block in right hand in third person.
  public var thirdPersonRightHand: matrix_float4x4
  /// Transform to use for block in left hand in third person.
  public var thirdPersonLeftHand: matrix_float4x4
  /// Transform to use for block in right hand in first person.
  public var firstPersonRightHand: matrix_float4x4
  /// Transform to use for block in left hand in first person.
  public var firstPersonLeftHand: matrix_float4x4
  /// Transform to use for block in inventory.
  public var gui: matrix_float4x4
  /// Transform to use for block on head?
  public var head: matrix_float4x4
  /// Transform to use for block on the ground.
  public var ground: matrix_float4x4
  /// Transform to use for block in item frames.
  public var fixed: matrix_float4x4
  
  public init(
    thirdPersonRightHand: matrix_float4x4,
    thirdPersonLeftHand: matrix_float4x4,
    firstPersonRightHand: matrix_float4x4,
    firstPersonLeftHand: matrix_float4x4,
    gui: matrix_float4x4,
    head: matrix_float4x4,
    ground: matrix_float4x4,
    fixed: matrix_float4x4
  ) {
    self.thirdPersonRightHand = thirdPersonRightHand
    self.thirdPersonLeftHand = thirdPersonLeftHand
    self.firstPersonRightHand = firstPersonRightHand
    self.firstPersonLeftHand = firstPersonLeftHand
    self.gui = gui
    self.head = head
    self.ground = ground
    self.fixed = fixed
  }
  
  public init(from jsonDisplayTransforms: JSONBlockModelDisplay) throws {
    thirdPersonRightHand = try jsonDisplayTransforms.thirdPersonRightHand?.toMatrix() ?? MatrixUtil.identity
    thirdPersonLeftHand = try jsonDisplayTransforms.thirdPersonLeftHand?.toMatrix() ?? MatrixUtil.identity
    firstPersonRightHand = try jsonDisplayTransforms.firstPersonRightHand?.toMatrix() ?? MatrixUtil.identity
    firstPersonLeftHand = try jsonDisplayTransforms.firstPersonLeftHand?.toMatrix() ?? MatrixUtil.identity
    gui = try jsonDisplayTransforms.gui?.toMatrix() ?? MatrixUtil.identity
    head = try jsonDisplayTransforms.head?.toMatrix() ?? MatrixUtil.identity
    ground = try jsonDisplayTransforms.ground?.toMatrix() ?? MatrixUtil.identity
    fixed = try jsonDisplayTransforms.fixed?.toMatrix() ?? MatrixUtil.identity
  }
}
