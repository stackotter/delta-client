import Metal
import DeltaCore

/// An error thrown by ``MetalTexturePalette``.
public enum MetalTexturePaletteError: LocalizedError {
  case failedToCreateCommandBuffer
  case failedToCreateBlitCommandEncoder

  public var errorDescription: String? {
    switch self {
      case .failedToCreateCommandBuffer:
        return "Failed to create command buffer for mipmap generation."
      case .failedToCreateBlitCommandEncoder:
        return "Failed to create blit command encoder for mipmap generation."
    }
  }
}

/// A Metal-specific wrapper for ``TexturePalette``. Handles animation-related buffers, and the
/// palette's static array texture.
public struct MetalTexturePalette {
  /// The underlying texture palette.
  public var palette: TexturePalette

  /// The texture palette's animation state.
  public var animationState: TexturePalette.AnimationState

  /// The underlying array texture.
  public var arrayTexture: MTLTexture

  /// The buffer storing texture states.
  public var textureStatesBuffer: MTLBuffer?

  /// The small buffer containing only the current time (we cannot just use the GPU's concept of
  /// time instead because the GPU does not use the same timebase as the CPU).
  public var timeBuffer: MTLBuffer?

  /// The global device to use for creating textures etc.
  public let device: MTLDevice

  /// The global command queue to use for creating textures etc.
  public let commandQueue: MTLCommandQueue

  /// For each texture there is a node that points to the previous animation frame and the next
  /// animation frame (in the array texture).
  public var textureStates: [TextureState]

  /// The time at which the palette was created measured in `CFAbsoluteTime`.
  public var creationTime: Double

  /// Maps a texture index to the index of its first frame (in the palette's array texture).
  public var textureIndexToFirstFrameIndex: [Int]

  /// The animation state of a texture in a format that is useful on the GPU.
  public struct TextureState {
    /// The array texture index of the texture's current animation frame.
    public var currentFrameIndex: UInt16
    /// The array texture index of the texture's next animation frame. `65535` indicates that the value
    /// is not present. Usually this would be represented using `Optional`, however that does not
    /// lend itself well to being copied to and interpreted by the GPU.
    public var nextFrameIndex: UInt16
    /// The time at which the previous update occured. Used for interpolation. Measured in ticks.
    public var previousUpdate: UInt32
    /// The time at which the next frame index will become the current frame index. Used for
    /// interpolation. Measured in ticks.
    public var nextUpdate: UInt32
  }

  /// Creates a new Metal wrapper for the given texture palette.
  public init(
    palette: TexturePalette,
    device: MTLDevice,
    commandQueue: MTLCommandQueue
  ) throws {
    self.palette = palette
    self.device = device
    self.commandQueue = commandQueue

    arrayTexture = try Self.createArrayTexture(
      for: palette,
      device: device,
      commandQueue: commandQueue
    )
    animationState = palette.defaultAnimationState

    var frameIndex = 0
    textureIndexToFirstFrameIndex = []
    textureStates = []
    creationTime = CFAbsoluteTimeGetCurrent()
    for texture in palette.textures {
      textureIndexToFirstFrameIndex.append(frameIndex)
      let frameTicks = texture.animation?.frames.first?.time ?? 0
      textureStates.append(TextureState(
        currentFrameIndex: UInt16(frameIndex),
        nextFrameIndex: 65535,
        previousUpdate: UInt32(0),
        nextUpdate: UInt32(frameTicks)
      ))
      frameIndex += texture.frameCount
    }

    textureStatesBuffer = device.makeBuffer(
      bytes: &textureStates,
      length: MemoryLayout<TextureState>.stride * textureStates.count
    )
    textureStatesBuffer?.label = "MetalTexturePalette.textureStatesBuffer"

    var tick: Float = 0
    timeBuffer = device.makeBuffer(bytes: &tick, length: MemoryLayout<Float>.stride)
    timeBuffer?.label = "MetalTexturePalette.timeBuffer"
  }

  /// Gets the index of the texture referred to by the given identifier if any.
  public func textureIndex(for identifier: Identifier) -> Int? {
    palette.textureIndex(for: identifier)
  }

  /// Returns a metal array texture containing all textures (including each individual animation
  /// frame of each texture if `includeAnimations` is set to `true`).
  public static func createArrayTexture(
    for palette: TexturePalette,
    device: MTLDevice,
    commandQueue: MTLCommandQueue,
    includeAnimations: Bool = true
  ) throws -> MTLTexture {
    let count: Int
    if includeAnimations {
      count = palette.textures.map{ texture in
        return texture.frameCount
      }.reduce(0, +)
    } else {
      count = palette.textures.count
    }

    let width = palette.width
    let height = palette.height

    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.width = width
    textureDescriptor.height = height
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.textureType = .type2DArray
    textureDescriptor.arrayLength = count

    #if os(macOS)
    textureDescriptor.storageMode = .managed
    #elseif os(iOS) || os(tvOS)
    textureDescriptor.storageMode = .shared
    #else
    #error("Unsupported platform, can't determine storageMode for texture")
    #endif

    textureDescriptor.mipmapLevelCount = 1 + Int(Foundation.log2(Double(width)).rounded(.down))

    guard let arrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.failedToCreateArrayTexture
    }

    arrayTexture.label = "arrayTexture"

    let bytesPerPixel = 4
    var frameIndex = 0
    for texture in palette.textures {
      let frameWidth = texture.width
      let frameCount = texture.frameCount
      let frameHeight = texture.height / frameCount
      let bytesPerRow = bytesPerPixel * frameWidth
      let bytesPerFrame = bytesPerRow * frameHeight

      guard frameHeight <= height else {
        frameIndex += frameCount
        continue
      }

      for frame in 0..<frameCount {
        let offset = frame * bytesPerFrame
        texture.image.withUnsafeBytes { pointer in
          arrayTexture.replace(
            region: MTLRegion(
              origin: MTLOrigin(x: 0, y: 0, z: 0),
              size: MTLSize(width: frameWidth, height: frameHeight, depth: 1)
            ),
            mipmapLevel: 0,
            slice: frameIndex,
            withBytes: pointer.baseAddress!.advanced(by: offset),
            bytesPerRow: bytesPerRow,
            bytesPerImage: bytesPerFrame
          )
        }
        frameIndex += 1

        if !includeAnimations {
          // Only include the first frame of each texture if animations aren't needed
          break
        }
      }
    }

    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      throw MetalTexturePaletteError.failedToCreateCommandBuffer
    }

    guard let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
      throw MetalTexturePaletteError.failedToCreateBlitCommandEncoder
    }

    textureDescriptor.storageMode = .private
    guard let privateArrayTexture = device.makeTexture(descriptor: textureDescriptor) else {
      throw RenderError.failedToCreatePrivateArrayTexture
    }

    blitCommandEncoder.copy(from: arrayTexture, to: privateArrayTexture)
    blitCommandEncoder.generateMipmaps(for: privateArrayTexture)
    blitCommandEncoder.endEncoding()
    commandBuffer.commit()

    return privateArrayTexture
  }

  public mutating func update() {
    var time = Float(CFAbsoluteTimeGetCurrent() - creationTime) / 0.05
    timeBuffer?.contents().copyMemory(from: &time, byteCount: MemoryLayout<Float>.stride)

    let tick = Int(time.rounded(.down))

    let updatedTextures = animationState.update(tick: tick)

    guard !updatedTextures.isEmpty else {
      return
    }

    for (textureIndex, latestUpdateTick) in updatedTextures {
      let texture = palette.textures[textureIndex]
      guard let animation = texture.animation else {
        continue
      }

      let frameIndex = animationState.frame(forTextureAt: textureIndex)
      let frame = animation.frames[frameIndex]

      let firstFrameIndex = textureIndexToFirstFrameIndex[textureIndex]
      let nextFrameIndex = (frameIndex + 1) % animation.frames.count
      textureStates[textureIndex] = TextureState(
        currentFrameIndex: UInt16(firstFrameIndex + frameIndex),
        nextFrameIndex: animation.interpolate ? UInt16(firstFrameIndex + nextFrameIndex) : 65535,
        previousUpdate: UInt32(latestUpdateTick),
        nextUpdate: UInt32(latestUpdateTick + frame.time)
      )
    }

    textureStatesBuffer?.contents().copyMemory(
      from: &textureStates,
      byteCount: MemoryLayout<TextureState>.stride * textureStates.count
    )
  }
}
