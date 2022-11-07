import DeltaCore
import MetalKit

extension TexturePalette {
  /// Returns a metal texture array on the given device, containing the first frame of each texture.
  public func createArrayTexture(
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    animationState: ArrayTextureAnimationState? = nil
  ) throws -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.width = width
    textureDescriptor.height = width
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.textureType = .type2DArray
    textureDescriptor.arrayLength = textures.count
    #if os(macOS)
    textureDescriptor.storageMode = .managed
    #elseif os(iOS)
    textureDescriptor.storageMode = .shared
    #else
    #error("Unsupported platform, can't determine storageMode for texture")
    #endif

    textureDescriptor.mipmapLevelCount = 1 + Int(Foundation.log2(Double(width)).rounded(.down))

    guard let arrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.failedToCreateTextureArray
    }

    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bytesPerFrame = bytesPerRow * width
    let animationState = animationState ?? ArrayTextureAnimationState(for: self)
    for (index, texture) in textures.enumerated() {
      let offset = animationState.frame(forTextureAt: index) * bytesPerFrame
      arrayTexture.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(width: width, height: width, depth: 1)
        ),
        mipmapLevel: 0,
        slice: index,
        withBytes: texture.bytes.withUnsafeBytes({ $0.baseAddress!.advanced(by: offset) }),
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerFrame
      )
    }

    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() {
        blitCommandEncoder.generateMipmaps(for: arrayTexture)
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
      } else {
        log.error("Failed to create blit command encoder to create mipmaps")
      }
    } else {
      log.error("Failed to create command buffer to create mipmaps")
    }

    return arrayTexture
  }

  public func updateArrayTexture(
    arrayTexture: MTLTexture,
    animationState: ArrayTextureAnimationState,
    updatedTextures: [Int],
    commandQueue: MTLCommandQueue
  ) {
    guard !updatedTextures.isEmpty else {
      return
    }

    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bytesPerFrame = bytesPerRow * width

    for index in updatedTextures {
      let texture = textures[index]
      let offset = animationState.frame(forTextureAt: index) * bytesPerFrame
      arrayTexture.replace(
        region: MTLRegion(
          origin: MTLOrigin(x: 0, y: 0, z: 0),
          size: MTLSize(width: width, height: width, depth: 1)
        ),
        mipmapLevel: 0,
        slice: index,
        withBytes: texture.bytes.withUnsafeBytes({ $0.baseAddress!.advanced(by: offset) }),
        bytesPerRow: bytesPerRow,
        bytesPerImage: bytesPerFrame
      )
    }

    // TODO: only regenerate necessary mipmaps
    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() {
        blitCommandEncoder.generateMipmaps(for: arrayTexture)
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
      } else {
        log.error("Failed to create blit command encoder to create mipmaps")
      }
    } else {
      log.error("Failed to create command buffer to create mipmaps")
    }
  }
}
