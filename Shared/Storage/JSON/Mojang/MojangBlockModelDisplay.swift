//
//  MojangBlockModelDisplay.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// Transforms to use when displaying a block in certain situations.
public struct MojangBlockModelDisplay: Codable {
  /// Transform to use for block in right hand in third person.
  public var thirdPersonRightHand: MojangBlockModelTransform?
  /// Transform to use for block in left hand in third person.
  public var thirdPersonLeftHand: MojangBlockModelTransform?
  /// Transform to use for block in right hand in first person.
  public var firstPersonRightHand: MojangBlockModelTransform?
  /// Transform to use for block in left hand in first person.
  public var firstPersonLeftHand: MojangBlockModelTransform?
  /// Transform to use for block in inventory.
  public var gui: MojangBlockModelTransform?
  /// Transform to use for block on head?
  public var head: MojangBlockModelTransform?
  /// Transform to use for block on the ground.
  public var ground: MojangBlockModelTransform?
  /// Transform to use for block in item frames.
  public var fixed: MojangBlockModelTransform?
  
  enum CodingKeys: String, CodingKey {
    case thirdPersonRightHand = "thirdperson_righthand"
    case thirdPersonLeftHand = "thirdperson_lefthand"
    case firstPersonRightHand = "firstperson_righthand"
    case firstPersonLeftHand = "firstperson_lefthand"
    case gui
    case head
    case ground
    case fixed
  }
}
