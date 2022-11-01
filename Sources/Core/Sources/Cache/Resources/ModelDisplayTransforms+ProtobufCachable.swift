import FirebladeMath

extension ModelDisplayTransforms: ProtobufCachable {
  public init(from message: ProtobufDisplayTransforms) throws {
    thirdPersonRightHand = try Mat4x4f(from: message.thirdPersonRightHand)
    thirdPersonLeftHand = try Mat4x4f(from: message.thirdPersonLeftHand)
    firstPersonRightHand = try Mat4x4f(from: message.firstPersonRightHand)
    firstPersonLeftHand = try Mat4x4f(from: message.firstPersonLeftHand)
    gui = try Mat4x4f(from: message.gui)
    head = try Mat4x4f(from: message.head)
    ground = try Mat4x4f(from: message.ground)
    fixed = try Mat4x4f(from: message.fixed)
  }

  public func cached() -> ProtobufDisplayTransforms {
    var message = ProtobufDisplayTransforms()
    message.thirdPersonRightHand = thirdPersonRightHand.data()
    message.thirdPersonLeftHand = thirdPersonLeftHand.data()
    message.firstPersonRightHand = firstPersonRightHand.data()
    message.firstPersonLeftHand = firstPersonLeftHand.data()
    message.gui = gui.data()
    message.head = head.data()
    message.ground = ground.data()
    message.fixed = fixed.data()
    return message
  }
}
