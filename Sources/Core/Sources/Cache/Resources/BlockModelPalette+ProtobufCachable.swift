import Foundation
import simd

extension BlockModelPalette: ProtobufCachable {
  public init(from message: ProtobufBlockModelPalette) throws {
    models.reserveCapacity(message.models.count)
    for cachedModel in message.models {
      var variants: [BlockModel] = []
      variants.reserveCapacity(cachedModel.variants.count)

      for variant in cachedModel.variants {
        variants.append(try BlockModel(from: variant))
      }

      models.append(variants)
    }

    displayTransforms.reserveCapacity(message.displayTransforms.count)
    for cachedDisplayTransforms in message.displayTransforms {
      displayTransforms.append(try BlockModelDisplayTransforms(from: cachedDisplayTransforms))
    }

    fullyOpaqueBlocks = message.fullyOpaqueBlocks
  }

  public func cached() -> ProtobufBlockModelPalette {
    var message = ProtobufBlockModelPalette()
    message.models.reserveCapacity(models.count)
    for model in models {
      var variants: [ProtobufBlockModel] = []
      variants.reserveCapacity(model.count)

      for variant in model {
        variants.append(variant.cached())
      }

      var cachedVariants = ProtobufVariants()
      cachedVariants.variants = variants
      message.models.append(cachedVariants)
    }

    message.displayTransforms.reserveCapacity(displayTransforms.count)
    for transforms in displayTransforms {
      message.displayTransforms.append(transforms.cached())
    }

    message.fullyOpaqueBlocks = fullyOpaqueBlocks

    return message
  }
}
