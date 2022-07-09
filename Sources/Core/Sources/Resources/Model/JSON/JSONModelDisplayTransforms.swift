import Foundation

/// Transforms to use when displaying models in certain situations.
struct JSONModelDisplayTransforms: Codable {
  /// Transform to use for displaying in right hand in third person.
  var thirdPersonRightHand: JSONModelTransform?
  /// Transform to use for displaying in left hand in third person.
  var thirdPersonLeftHand: JSONModelTransform?
  /// Transform to use for displaying in right hand in first person.
  var firstPersonRightHand: JSONModelTransform?
  /// Transform to use for displaying in left hand in first person.
  var firstPersonLeftHand: JSONModelTransform?
  /// Transform to use for displaying in inventory.
  var gui: JSONModelTransform?
  /// Transform to use for displaying on head?
  var head: JSONModelTransform?
  /// Transform to use for displaying on the ground.
  var ground: JSONModelTransform?
  /// Transform to use for displaying in item frames.
  var fixed: JSONModelTransform?

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

  func merge(withChild child: JSONModelDisplayTransforms) -> JSONModelDisplayTransforms {
    let thirdPersonRightHand = child.thirdPersonRightHand ?? thirdPersonRightHand
    let thirdPersonLeftHand = child.thirdPersonLeftHand ?? thirdPersonLeftHand
    let firstPersonRightHand = child.firstPersonRightHand ?? firstPersonRightHand
    let firstPersonLeftHand = child.firstPersonLeftHand ?? firstPersonLeftHand
    let gui = child.gui ?? gui
    let head = child.head ?? head
    let ground = child.ground ?? ground
    let fixed = child.fixed ?? fixed

    return JSONModelDisplayTransforms(
      thirdPersonRightHand: thirdPersonRightHand,
      thirdPersonLeftHand: thirdPersonLeftHand,
      firstPersonRightHand: firstPersonRightHand,
      firstPersonLeftHand: firstPersonLeftHand,
      gui: gui,
      head: head,
      ground: ground,
      fixed: fixed
    )
  }
}
