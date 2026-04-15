import MetalKit
import DeltaCore

extension Font {
  /// Creates an array texture containing the font's atlases.
  /// - Parameters:
  ///   - device: The device to create the texture with.
  ///   - commandQueue: The command queue to use for blit operations.
  /// - Returns: An array texture containing the textures in ``textures``.
  public func createArrayTexture(
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws -> MTLTexture {
    guard !textures.isEmpty else {
      throw FontError.emptyFont
    }

    // Calculate minimum dimensions to fit all textures.
    guard let width = textures.map({ texture in
      return texture.width
    }).max() else {
      throw FontError.failedToGetArrayTextureWidth
    }

    guard let height = textures.map({ texture in
      return texture.height
    }).max() else {
      throw FontError.failedToGetArrayTextureHeight
    }

    // Create texture descriptor
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.width = width
    textureDescriptor.height = height
    textureDescriptor.arrayLength = textures.count
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.textureType = .type2DArray
    #if os(macOS)
    textureDescriptor.storageMode = .managed
    #elseif os(iOS) || os(tvOS)
    textureDescriptor.storageMode = .shared
    #else
    #error("Unsupported platform, can't determine storageMode for texture")
    #endif

    guard let arrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw FontError.failedToCreateArrayTexture
    }

    // Populate texture
    let bytesPerPixel = 4
    for (index, texture) in textures.enumerated() {
      let bytesPerRow = bytesPerPixel * texture.width
      let byteCount = bytesPerRow * texture.height

      texture.image.withUnsafeBytes { pointer in
        arrayTexture.replace(
          region: MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(
              width: texture.width,
              height: texture.height,
              depth: 1
            )
          ),
          mipmapLevel: 0,
          slice: index,
          withBytes: pointer.baseAddress!,
          bytesPerRow: bytesPerRow,
          bytesPerImage: byteCount
        )
      }
    }

    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
    else {
      throw RenderError.failedToCreateBlitCommandEncoder
    }

    textureDescriptor.storageMode = .private
    guard let privateArrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.failedToCreatePrivateArrayTexture
    }

    blitCommandEncoder.copy(from: arrayTexture, to: privateArrayTexture)
    blitCommandEncoder.endEncoding()
    commandBuffer.commit()

    return privateArrayTexture
  }
}
