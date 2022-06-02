extension BlockModelRenderDescriptor: ProtobufCachable {
  public init(from message: ProtobufBlockModelPartDescriptor) {
    model = Identifier(
      namespace: message.identifierNamespace,
      name: message.identifierName)
    xRotationDegrees = Int(message.xRotationDegrees)
    yRotationDegrees = Int(message.yRotationDegrees)
    uvLock = message.uvLock
  }
  
  public func cached() -> ProtobufBlockModelPartDescriptor {
    var message = ProtobufBlockModelPartDescriptor()
    message.identifierNamespace = model.namespace
    message.identifierName = model.name
    message.xRotationDegrees = Int32(xRotationDegrees)
    message.yRotationDegrees = Int32(yRotationDegrees)
    message.uvLock = uvLock
    return message
  }
}
