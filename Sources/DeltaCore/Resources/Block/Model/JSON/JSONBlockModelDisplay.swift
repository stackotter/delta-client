//
//  JSONBlockModelDisplay.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// Transforms to use when displaying a block in certain situations.
public struct JSONBlockModelDisplay: Codable {
  /// Transform to use for block in right hand in third person.
  public var thirdPersonRightHand: JSONBlockModelTransform?
  /// Transform to use for block in left hand in third person.
  public var thirdPersonLeftHand: JSONBlockModelTransform?
  /// Transform to use for block in right hand in first person.
  public var firstPersonRightHand: JSONBlockModelTransform?
  /// Transform to use for block in left hand in first person.
  public var firstPersonLeftHand: JSONBlockModelTransform?
  /// Transform to use for block in inventory.
  public var gui: JSONBlockModelTransform?
  /// Transform to use for block on head?
  public var head: JSONBlockModelTransform?
  /// Transform to use for block on the ground.
  public var ground: JSONBlockModelTransform?
  /// Transform to use for block in item frames.
  public var fixed: JSONBlockModelTransform?
  
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
