//
//  BlockModelDisplayTransforms.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore
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
  
  init(from mojangDisplayTransforms: MojangBlockModelDisplay) throws {
    thirdPersonRightHand = try mojangDisplayTransforms.thirdPersonRightHand?.toMatrix() ?? MatrixUtil.identity
    thirdPersonLeftHand = try mojangDisplayTransforms.thirdPersonLeftHand?.toMatrix() ?? MatrixUtil.identity
    firstPersonRightHand = try mojangDisplayTransforms.firstPersonRightHand?.toMatrix() ?? MatrixUtil.identity
    firstPersonLeftHand = try mojangDisplayTransforms.firstPersonLeftHand?.toMatrix() ?? MatrixUtil.identity
    gui = try mojangDisplayTransforms.gui?.toMatrix() ?? MatrixUtil.identity
    head = try mojangDisplayTransforms.head?.toMatrix() ?? MatrixUtil.identity
    ground = try mojangDisplayTransforms.ground?.toMatrix() ?? MatrixUtil.identity
    fixed = try mojangDisplayTransforms.fixed?.toMatrix() ?? MatrixUtil.identity
  }
}
