extension ItemModelPalette: BinaryCacheable {
  public static var serializationFormatVersion: Int {
    return 0
  }

  public func serialize(into buffer: inout Buffer) {
    models.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> ItemModelPalette {
    return ItemModelPalette(
      try .deserialize(from: &buffer)
    )
  }
}

extension ItemModel: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    switch self {
      case .layered(let textureIndices, let transforms):
        0.serialize(into: &buffer)
        textureIndices.serialize(into: &buffer)
        transforms.serialize(into: &buffer)
      case .blockModel(let id):
        1.serialize(into: &buffer)
        id.serialize(into: &buffer)
      case .entity(let identifier, let transforms):
        2.serialize(into: &buffer)
        identifier.serialize(into: &buffer)
        transforms.serialize(into: &buffer)
      case .empty:
        3.serialize(into: &buffer)
    }
  }

  public static func deserialize(from buffer: inout Buffer) throws -> ItemModel {
    let caseId = try Int.deserialize(from: &buffer)
    switch caseId {
      case 0:
        return .layered(
          textureIndices: try .deserialize(from: &buffer),
          transforms: try .deserialize(from: &buffer)
        )
      case 1:
        return .blockModel(id: try .deserialize(from: &buffer))
      case 2:
        return .entity(
          try .deserialize(from: &buffer),
          transforms: try .deserialize(from: &buffer)
        )
      case 3:
        return .empty
      default:
        throw BinarySerializationError.invalidCaseId(caseId, type: String(describing: Self.self))
    }
  }
}

extension ItemModelTexture: BitwiseCopyable {}
