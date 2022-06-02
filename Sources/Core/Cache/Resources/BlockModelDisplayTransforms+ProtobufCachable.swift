import simd

extension BlockModelDisplayTransforms: ProtobufCachable {
  public init(from message: ProtobufDisplayTransforms) throws {
    thirdPersonRightHand = try matrix_float4x4(from: message.thirdPersonRightHand)
    thirdPersonLeftHand = try matrix_float4x4(from: message.thirdPersonLeftHand)
    firstPersonRightHand = try matrix_float4x4(from: message.firstPersonRightHand)
    firstPersonLeftHand = try matrix_float4x4(from: message.firstPersonLeftHand)
    gui = try matrix_float4x4(from: message.gui)
    head = try matrix_float4x4(from: message.head)
    ground = try matrix_float4x4(from: message.ground)
    fixed = try matrix_float4x4(from: message.fixed)
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
