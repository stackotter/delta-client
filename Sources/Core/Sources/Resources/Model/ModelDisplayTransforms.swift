import Foundation
import FirebladeMath

/// The transforms to apply when displaying rendering a model in different situations.
public struct ModelDisplayTransforms {
  /// Transform to use for displaying in right hand in third person.
  public var thirdPersonRightHand: Mat4x4f
  /// Transform to use for displaying in left hand in third person.
  public var thirdPersonLeftHand: Mat4x4f
  /// Transform to use for displaying in right hand in first person.
  public var firstPersonRightHand: Mat4x4f
  /// Transform to use for displaying in left hand in first person.
  public var firstPersonLeftHand: Mat4x4f
  /// Transform to use for displaying in inventory.
  public var gui: Mat4x4f
  /// Transform to use for displaying on head?
  public var head: Mat4x4f
  /// Transform to use for displaying on the ground.
  public var ground: Mat4x4f
  /// Transform to use for displaying in item frames.
  public var fixed: Mat4x4f

  public init(
    thirdPersonRightHand: Mat4x4f,
    thirdPersonLeftHand: Mat4x4f,
    firstPersonRightHand: Mat4x4f,
    firstPersonLeftHand: Mat4x4f,
    gui: Mat4x4f,
    head: Mat4x4f,
    ground: Mat4x4f,
    fixed: Mat4x4f
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

  init(from jsonDisplayTransforms: JSONModelDisplayTransforms) throws {
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
