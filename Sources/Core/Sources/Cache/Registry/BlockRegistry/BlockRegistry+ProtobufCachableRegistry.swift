extension BlockRegistry: ProtobufCachableRegistry {
  public static func getCacheFileName() -> String {
    "blocks.bin"
  }

  public init(from message: ProtobufBlockRegistry) throws {
    blocks.reserveCapacity(message.blocks.count)
    for block in message.blocks {
      blocks.append(try Block(from: block))
    }

    renderDescriptors.reserveCapacity(message.renderDescriptors.count)
    for modelDescriptor in message.renderDescriptors {
      var variantDescriptors: [[BlockModelRenderDescriptor]] = []
      variantDescriptors.reserveCapacity(modelDescriptor.variants.count)
      for variantDescriptor in modelDescriptor.variants {
        var partDescriptors: [BlockModelRenderDescriptor] = []
        partDescriptors.reserveCapacity(variantDescriptor.parts.count)
        for partDescriptor in variantDescriptor.parts {
          partDescriptors.append(BlockModelRenderDescriptor(from: partDescriptor))
        }
        variantDescriptors.append(partDescriptors)
      }
      renderDescriptors.append(variantDescriptors)
    }

    selfCullingBlocks.reserveCapacity(message.selfCullingBlocks.count)
    for blockId in message.selfCullingBlocks {
      selfCullingBlocks.insert(Int(blockId))
    }

    airBlocks.reserveCapacity(message.airBlocks.count)
    for blockId in airBlocks {
      airBlocks.insert(Int(blockId))
    }
  }

  public func cached() -> ProtobufBlockRegistry {
    var message = ProtobufBlockRegistry()

    message.blocks.reserveCapacity(blocks.count)
    for block in blocks {
      message.blocks.append(block.cached())
    }

    message.renderDescriptors.reserveCapacity(renderDescriptors.count)
    for descriptor in renderDescriptors {
      var variantDescriptors: [ProtobufBlockModelVariantDescriptor] = []
      variantDescriptors.reserveCapacity(descriptor.count)

      for variantDescriptor in descriptor {
        var partDescriptors: [ProtobufBlockModelPartDescriptor] = []
        partDescriptors.reserveCapacity(variantDescriptor.count)

        for partDescriptor in variantDescriptor {
          partDescriptors.append(partDescriptor.cached())
        }

        var message = ProtobufBlockModelVariantDescriptor()
        message.parts = partDescriptors
        variantDescriptors.append(message)
      }

      var modelDescriptor = ProtobufBlockModelDescriptor()
      modelDescriptor.variants = variantDescriptors
      message.renderDescriptors.append(modelDescriptor)
    }

    message.selfCullingBlocks.reserveCapacity(selfCullingBlocks.count)
    for blockId in selfCullingBlocks {
      message.selfCullingBlocks.append(Int32(blockId))
    }

    message.airBlocks.reserveCapacity(airBlocks.count)
    for blockId in airBlocks {
      message.airBlocks.append(Int32(blockId))
    }

    return message
  }
}
