import FirebladeMath

extension BlockModelElement: ProtobufCachable {
  public init(from message: ProtobufBlockModelElement) throws {
    transformation = try Mat4x4f(from: message.transformation)
    shade = message.shade

    faces = []
    faces.reserveCapacity(message.faces.count)
    for face in message.faces {
      faces.append(try BlockModelFace(from: face))
    }
  }

  public func cached() -> ProtobufBlockModelElement {
    var message = ProtobufBlockModelElement()
    message.transformation = transformation.data()
    message.shade = shade

    message.faces.reserveCapacity(faces.count)
    for face in faces {
      message.faces.append(face.cached())
    }

    return message
  }
}
