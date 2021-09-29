import Foundation

public enum TextureError: LocalizedError {
  /// The texture's height must be a multiple of the width.
  case invalidDimensions(width: Int, height: Int)
  /// Texture dimensions must be powers of two.
  case widthNotPowerOfTwo(width: Int)
  /// Failed to create an image provider to read the texture from the given file.
  case failedToCreateImageProvider
  /// Failed to read the texture from the given file.
  case failedToReadTextureImage
  /// Failed to get the raw bytes of the texture.
  case failedToGetTextureBytes(Error)
  /// Failed to create a `CGContext` for the given texture.
  case failedToCreateContext
  /// Failed to get the bytes of the `CGContext` created to format the texture.
  case failedToGetContextBytes
  /// The animation mcmeta file for the texture contains invalid frame metadata.
  case invalidFrameMetadata
  /// The animation data for an animated texture was invalid or missing.
  case failedToLoadTextureAnimation(Error)
  /// The target width for the texture is not a power of two.
  case targetWidthNotPowerOfTwo(targetWidth: Int)
}

/// A texture and its metadata.
public struct Texture {
  /// the width of the texture in pixels.
  public var width: Int
  /// The height of the texture in pixels.
  public var height: Int
  
  /// The texture's type.
  public var type: TextureType
  /// The texture's byte representation.
  public var bytes: [UInt8]
  
  /// A description of how to animate this texture.
  public var animation: Animation?
  
  /// Read the texture contained in the given image file. Must be a PNG.
  public init(from image: CGImage, withAnimationFile animationMetadataFile: URL, scaledToWidth targetWidth: Int, colorSpace: CGColorSpace, bitmapInfo: UInt32, isLeaves: Bool = false) throws {
    // The height of the texture must be a multiple of the width
    guard image.height % image.width == 0 else {
      throw TextureError.invalidDimensions(width: image.width, height: image.height)
    }
    
    // The width must be a power of two
    guard image.width.isPowerOfTwo else {
      throw TextureError.widthNotPowerOfTwo(width: image.width)
    }
    
    guard targetWidth.isPowerOfTwo else {
      throw TextureError.targetWidthNotPowerOfTwo(targetWidth: targetWidth)
    }
    
    // Calculate new dimensions
    let scaleFactor = targetWidth / image.width
    width = scaleFactor * image.width
    height = scaleFactor * image.height
    
    // Load animation metadata if necessary
    let numFrames = height / width
    if numFrames > 1 {
      do {
        let data = try Data(contentsOf: animationMetadataFile)
        let animationMCMeta = try JSONDecoder().decode(AnimationMCMeta.self, from: data)
        animation = Animation(from: animationMCMeta, maxFrameIndex: numFrames)
      } catch {
        throw TextureError.failedToLoadTextureAnimation(error)
      }
    }
    
    // Load texture data
    do {
      bytes = try image.getBytes(with: colorSpace, and: bitmapInfo, scaledBy: scaleFactor)
    } catch {
      throw TextureError.failedToGetTextureBytes(error)
    }
    
    // TODO: don't hardcode the behaviour of leaves like that, make texture palette loading more flexible somehow
    // Figure out what type of texture this is
    if isLeaves {
      type = .opaque
    } else {
      type = Self.typeOfTexture(withBytes: bytes, width: width, height: height, bytesPerPixel: image.bitsPerPixel / 8)
      if type != .opaque {
        fixTransparentPixels()
      }
    }
  }
  
  /// Returns the type of a texture.
  private static func typeOfTexture(withBytes bytes: [UInt8], width: Int, height: Int, bytesPerPixel: Int) -> TextureType {
    var type = TextureType.opaque
    
    for i in 0..<(width * height) {
      let alpha = bytes[(i + 1) * bytesPerPixel - 1]
      
      if alpha == 0 {
        type = .transparent
        // We don't break here because it can still be overidden by translucent
      } else if alpha < 255 {
        type = .translucent
        break
      }
    }
    
    return type
  }
  
  /// Fixes the colour values of transparent pixels to vaguely represent the colours of the pixels around them to help with mipmapping.
  /// This function is probably really slow, I haven't checked yet.
  private mutating func fixTransparentPixels() {
    for x in 0..<width {
      // For each transparent pixel copy the color values from above
      for y in 0..<height {
        var pixel = getPixelAt(x: x, y: y)
        if pixel.a == 0 && y != 0 {
          pixel = getPixelAt(x: x, y: y - 1)
          pixel.a = 0
          setPixelAt(x: x, y: y, to: pixel)
        }
      }
      
      // Do the same but the other way
      for y in 1...height {
        let y = height - y
        var pixel = getPixelAt(x: x, y: y)
        if pixel.a == 0 && y != height - 1 {
          pixel = getPixelAt(x: x, y: y + 1)
          pixel.a = 0
          setPixelAt(x: x, y: y, to: pixel)
        }
      }
    }
    
    // Do the whole thing again but horizontally
    for y in 0..<height {
      // For each transparent pixel copy the color values from the left
      for x in 0..<width {
        var pixel = getPixelAt(x: x, y: y)
        if pixel.a == 0 && x != 0 {
          pixel = getPixelAt(x: x - 1, y: y)
          pixel.a = 0
          setPixelAt(x: x, y: y, to: pixel)
        }
      }
      
      // Do the same but the other way
      for x in 1...width {
        let x = width - x
        var pixel = getPixelAt(x: x, y: y)
        if pixel.a == 0 && x != width - 1 {
          pixel = getPixelAt(x: x + 1, y: y)
          pixel.a = 0
          setPixelAt(x: x, y: y, to: pixel)
        }
      }
    }
  }
  
  /// Returns the pixel at the given location. Does not check bounds.
  private func getPixelAt(x: Int, y: Int) -> Pixel {
    let index = (y * width + x) * 4 // 4 is the number of bytes per pixel
    let b = bytes[index]
    let g = bytes[index + 1]
    let r = bytes[index + 2]
    let a = bytes[index + 3]
    return Pixel(r: r, g: g, b: b, a: a)
  }
  
  /// Sets the pixel at the given coordinates to the given pixel data.
  private mutating func setPixelAt(x: Int, y: Int, to pixel: Pixel) {
    let index = (y * width + x) * 4 // 4 is the number of bytes per pixel
    bytes[index] = pixel.b
    bytes[index + 1] = pixel.g
    bytes[index + 2] = pixel.r
    bytes[index + 3] = pixel.a
  }
}

extension Texture {
  private struct Pixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
  }
}
