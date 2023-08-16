extension Block.Tint: BitwiseCopyable {}
extension Block.Offset: BitwiseCopyable {}
extension Block.PhysicalMaterial: BitwiseCopyable {}
extension Block.LightMaterial: BitwiseCopyable {}
extension Block.SoundMaterial: BitwiseCopyable {}
extension FluidState: BitwiseCopyable {}
extension AxisAlignedBoundingBox: BitwiseCopyable {}
extension Block.StateProperties: BitwiseCopyable {}

extension BlockRegistry: BinaryCacheable {
  public static var serializationFormatVersion: Int {
    return 0
  }

  public func serialize(into buffer: inout Buffer) {
    blocks.serialize(into: &buffer)
    renderDescriptors.serialize(into: &buffer)
    selfCullingBlocks.serialize(into: &buffer)
    airBlocks.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockRegistry {
    return BlockRegistry(
      blocks: try .deserialize(from: &buffer),
      renderDescriptors: try .deserialize(from: &buffer),
      selfCullingBlocks: try .deserialize(from: &buffer),
      airBlocks: try .deserialize(from: &buffer)
    )
  }
}

extension Block: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    id.serialize(into: &buffer)
    vanillaParentBlockId.serialize(into: &buffer)
    identifier.serialize(into: &buffer)
    className.serialize(into: &buffer)
    fluidState.serialize(into: &buffer)
    tint.serialize(into: &buffer)
    offset.serialize(into: &buffer)
    material.serialize(into: &buffer)
    lightMaterial.serialize(into: &buffer)
    soundMaterial.serialize(into: &buffer)
    shape.serialize(into: &buffer)
    stateProperties.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Block {
    return Block(
      id: try .deserialize(from: &buffer),
      vanillaParentBlockId: try .deserialize(from: &buffer),
      identifier: try .deserialize(from: &buffer),
      className: try .deserialize(from: &buffer),
      fluidState: try .deserialize(from: &buffer),
      tint: try .deserialize(from: &buffer),
      offset: try .deserialize(from: &buffer),
      material: try .deserialize(from: &buffer),
      lightMaterial: try .deserialize(from: &buffer),
      soundMaterial: try .deserialize(from: &buffer),
      shape: try .deserialize(from: &buffer),
      stateProperties: try .deserialize(from: &buffer)
    )
  }
}

extension Block.Shape: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    isDynamic.serialize(into: &buffer)
    isLarge.serialize(into: &buffer)
    collisionShape.serialize(into: &buffer)
    outlineShape.serialize(into: &buffer)
    occlusionShapeIds.serialize(into: &buffer)
    isSturdy.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> Block.Shape {
    return Block.Shape(
      isDynamic: try .deserialize(from: &buffer),
      isLarge: try .deserialize(from: &buffer),
      collisionShape: try .deserialize(from: &buffer),
      outlineShape: try .deserialize(from: &buffer),
      occlusionShapeIds: try .deserialize(from: &buffer),
      isSturdy: try .deserialize(from: &buffer)
    )
  }
}

extension CompoundBoundingBox: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    aabbs.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> CompoundBoundingBox {
    return CompoundBoundingBox(try .deserialize(from: &buffer))
  }
}

extension BlockModelRenderDescriptor: BinarySerializable {
  public func serialize(into buffer: inout Buffer) {
    model.serialize(into: &buffer)
    xRotationDegrees.serialize(into: &buffer)
    yRotationDegrees.serialize(into: &buffer)
    uvLock.serialize(into: &buffer)
  }

  public static func deserialize(from buffer: inout Buffer) throws -> BlockModelRenderDescriptor {
    return BlockModelRenderDescriptor(
      model: try .deserialize(from: &buffer),
      xRotationDegrees: try .deserialize(from: &buffer),
      yRotationDegrees: try .deserialize(from: &buffer),
      uvLock: try .deserialize(from: &buffer)
    )
  }
}
