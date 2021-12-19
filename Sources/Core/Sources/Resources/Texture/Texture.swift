import Foundation
import ColorSync
import ZippyJSON

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
  /// The animation to use when rendering this texture.
  public var animation: Animation?
  
  /// Loads a texture.
  /// - Parameters:
  ///   - pngFile: The png file containing the texture.
  ///   - type: The type of the texture. Calculated if not specified.
  ///   - targetWidth: Scales the image to this width.
  ///   - checkDimensions: If `true`, the texture's width must be a power of two, and the height must be a multiple of the width. `targetWidth` must also be a power of two if present.
  public init(pngFile: URL, type: TextureType? = nil, scaledToWidth targetWidth: Int? = nil, checkDimensions: Bool = false) throws {
    let image = try CGImage(pngFile: pngFile)
    try self.init(image: image, type: type, scaledToWidth: targetWidth, checkDimensions: checkDimensions)
  }
  
  /// Loads a texture.
  /// - Parameters:
  ///   - image: The image containing the texture.
  ///   - type: The type of the texture. Calculated if not specified.
  ///   - targetWidth: Scales the image to this width.
  ///   - checkDimensions: If `true`, the texture's width must be a power of two, and the height must be a multiple of the width. `targetWidth` must also be a power of two if present.
  public init(image: CGImage, type: TextureType? = nil, scaledToWidth targetWidth: Int? = nil, checkDimensions: Bool = false) throws {
    if checkDimensions {
      // The height of the texture must be a multiple of the width
      guard image.height % image.width == 0 else {
        throw TextureError.invalidDimensions(width: image.width, height: image.height)
      }
      
      // The width must be a power of two
      guard image.width.isPowerOfTwo else {
        throw TextureError.widthNotPowerOfTwo(width: image.width)
      }
      
      // The target width must be a power of two
      if let targetWidth = targetWidth {
        guard targetWidth.isPowerOfTwo else {
          throw TextureError.targetWidthNotPowerOfTwo(targetWidth: targetWidth)
        }
      }
    }
    
    // Calculate new dimensions
    let scaleFactor: Int
    if let targetWidth = targetWidth {
      scaleFactor = targetWidth / image.width
    } else {
      scaleFactor = 1
    }
    
    width = scaleFactor * image.width
    height = scaleFactor * image.height
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = UInt32(Int(kColorSyncAlphaPremultipliedFirst.rawValue) | kColorSyncByteOrder32Little)
    
    bytes = try image.getBytes(with: colorSpace, and: bitmapInfo, scaledBy: scaleFactor)
    self.type = type ?? Self.typeOfTexture(withBytes: bytes, width: width, height: height, bytesPerPixel: image.bitsPerPixel / 8)
    
    if self.type == .translucent {
      unpremultiply()
    }
  }
  
  /// Loads a texture animation from a json file in a resource pack, and then sets is as this texture's animation
  /// - Parameter animationMetadataFile: The animation descriptor file.
  public mutating func setAnimation(file animationMetadataFile: URL) throws {
    let numFrames = height / width
    do {
      let data = try Data(contentsOf: animationMetadataFile)
      let animationMCMeta = try ZippyJSONDecoder().decode(AnimationMCMeta.self, from: data)
      animation = Animation(from: animationMCMeta, maxFrameIndex: numFrames)
    } catch {
      throw TextureError.failedToLoadTextureAnimation(error)
    }
  }
  
  /// Fixes the colour values of transparent pixels to vaguely represent the colours of the pixels around them to help with mipmapping.
  /// This function is probably really slow, I haven't checked yet. Nope, it doesn't seem to be too slow.
  public mutating func fixTransparentPixels() {
    for x in 0..<width {
      // For each transparent pixel copy the color values from above
      for y in 0..<height {
        var pixel = getPixel(atX: x, y: y)
        if pixel.a == 0 && y != 0 {
          pixel = getPixel(atX: x, y: y - 1)
          pixel.a = 0
          setPixel(atX: x, y: y, to: pixel)
        }
      }
      
      // Do the same but the other way
      for y in 1...height {
        let y = height - y
        var pixel = getPixel(atX: x, y: y)
        if pixel.a == 0 && y != height - 1 {
          pixel = getPixel(atX: x, y: y + 1)
          pixel.a = 0
          setPixel(atX: x, y: y, to: pixel)
        }
      }
    }
    
    // Do the whole thing again but horizontally
    for y in 0..<height {
      // For each transparent pixel copy the color values from the left
      for x in 0..<width {
        var pixel = getPixel(atX: x, y: y)
        if pixel.a == 0 && x != 0 {
          pixel = getPixel(atX: x - 1, y: y)
          pixel.a = 0
          setPixel(atX: x, y: y, to: pixel)
        }
      }
      
      // Do the same but the other way
      for x in 1...width {
        let x = width - x
        var pixel = getPixel(atX: x, y: y)
        if pixel.a == 0 && x != width - 1 {
          pixel = getPixel(atX: x + 1, y: y)
          pixel.a = 0
          setPixel(atX: x, y: y, to: pixel)
        }
      }
    }
  }
  
  /// Returns the pixel at the given location. Does not check bounds.
  public func getPixel(atX x: Int, y: Int) -> Pixel {
    let index = (y * width + x) * 4 // 4 is the number of bytes per pixel
    let b = bytes[index]
    let g = bytes[index + 1]
    let r = bytes[index + 2]
    let a = bytes[index + 3]
    return Pixel(r: r, g: g, b: b, a: a)
  }
  
  /// Sets the pixel at the given coordinates to the given pixel data.
  public mutating func setPixel(atX x: Int, y: Int, to pixel: Pixel) {
    let index = (y * width + x) * 4 // 4 is the number of bytes per pixel
    bytes[index] = pixel.b
    bytes[index + 1] = pixel.g
    bytes[index + 2] = pixel.r
    bytes[index + 3] = pixel.a
  }
    
  /// Sets the alpha components of the texutre to a specified value. Alpha value is bound to a range (0...255 inclusive).
  public mutating func setAlpha(_ alpha: UInt8) {
    let clampAlpha = min(max(alpha, 0), 255)
    for x in 0..<width {
      for y in 0..<height {
        let pixel = getPixel(atX: x, y: y)
        let newPixel = Pixel(
          r: UInt8(pixel.r),
          g: UInt8(pixel.g),
          b: UInt8(pixel.b),
          a: UInt8(clampAlpha))
        setPixel(atX: x, y: y, to: newPixel)
      }
    }
  }
  
  /// Divides the rgb components by the alpha component to unpremultiply the alpha.
  public mutating func unpremultiply() {
    for x in 0..<width {
      for y in 0..<height {
        let pixel = getPixel(atX: x, y: y)
        if pixel.a == 0 {
          continue
        }
        
        let a = Float(pixel.a) / 255
        let r = Float(pixel.r) / a
        let g = Float(pixel.g) / a
        let b = Float(pixel.b) / a
        let newPixel = Pixel(
          r: UInt8(r),
          g: UInt8(g),
          b: UInt8(b),
          a: pixel.a)
        setPixel(atX: x, y: y, to: newPixel)
      }
    }
  }
  
  /// Finds the type of a texture by inspecting its pixels.
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
}

extension Texture {
  /// A texture pixel.
  public struct Pixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
  }
}
