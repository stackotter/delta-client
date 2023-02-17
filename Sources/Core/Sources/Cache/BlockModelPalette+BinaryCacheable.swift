extension DirectionSet: BitwiseCopyable {}
extension TextureType: BitwiseCopyable {}
extension Direction: BitwiseCopyable {}
extension ModelDisplayTransforms: BitwiseCopyable {}

extension BlockModelPalette: BinaryCacheable {
  public static var serializationFormatVersion: Int {
    return 0
  }

  public func serialize(into buffer: inout Buffer) {
    models.serialize(into: &buffer)
    displayTransforms.serialize(into: &buffer)
    identifierToIndex.serialize(into: &buffer)
    fullyOpaqueBlocks.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockModelPalette {
    return BlockModelPalette(
      models: try .deserialize(from: &buffer),
      displayTransforms: try .deserialize(from: &buffer),
      identifierToIndex: try .deserialize(from: &buffer),
      fullyOpaqueBlocks: try [Bool].deserialize(from: &buffer)
    )
  }
}

extension Identifier: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    namespace.serialize(into: &buffer)
    name.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Identifier {
    return Identifier(
      namespace: try .deserialize(from: &buffer),
      name: try .deserialize(from: &buffer)
    )
  }
}

extension BlockModel: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    parts.serialize(into: &buffer)
    cullingFaces.serialize(into: &buffer)
    cullableFaces.serialize(into: &buffer)
    nonCullableFaces.serialize(into: &buffer)
    textureType.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockModel {
    return BlockModel(
      parts: try .deserialize(from: &buffer),
      cullingFaces: try .deserialize(from: &buffer),
      cullableFaces: try .deserialize(from: &buffer),
      nonCullableFaces: try .deserialize(from: &buffer),
      textureType: try .deserialize(from: &buffer)
    )
  }
}

extension BlockModelPart: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    ambientOcclusion.serialize(into: &buffer)
    displayTransformsIndex.serialize(into: &buffer)
    elements.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockModelPart {
    return BlockModelPart(
      ambientOcclusion: try .deserialize(from: &buffer),
      displayTransformsIndex: try .deserialize(from: &buffer),
      elements: try .deserialize(from: &buffer)
    )
  }
}

extension BlockModelElement: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    transformation.serialize(into: &buffer)
    shade.serialize(into: &buffer)
    faces.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockModelElement {
    return BlockModelElement(
      transformation: try .deserialize(from: &buffer),
      shade: try .deserialize(from: &buffer),
      faces: try .deserialize(from: &buffer)
    )
  }
}

extension BlockModelFace: BitwiseCopyable {}
