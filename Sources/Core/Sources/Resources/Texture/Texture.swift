import Foundation
import SwiftImage

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

  public var errorDescription: String? {
    switch self {
      case .invalidDimensions(let width, let height):
        return """
        The texture's height must be a multiple of the width.
        Width: \(width)
        Height: \(height)
        """
      case .widthNotPowerOfTwo(let width):
        return """
        Texture dimensions must be powers of two.
        Width: \(width)
        """
      case .failedToCreateImageProvider:
        return "Failed to create an image provider to read the texture from the given file."
      case .failedToReadTextureImage:
        return "Failed to read the texture from the given file."
      case .failedToGetTextureBytes(let error):
        return """
        Failed to get the raw bytes of the texture.
        Reason: \(error.localizedDescription)
        """
      case .failedToCreateContext:
        return "Failed to create a `CGContext` for the given texture."
      case .failedToGetContextBytes:
        return "Failed to get the bytes of the `CGContext` created to format the texture."
      case .invalidFrameMetadata:
        return "The animation mcmeta file for the texture contains invalid frame metadata."
      case .failedToLoadTextureAnimation(let error):
        return """
        The animation data for an animated texture was invalid or missing.
        Reason: \(error.localizedDescription)
        """
      case .targetWidthNotPowerOfTwo(let targetWidth):
        return """
        The target width for the texture is not a power of two.
        Target width: \(targetWidth)
        """
    }
  }
}

/// A texture and its metadata.
public struct Texture {
  /// the width of the texture in pixels.
  public var width: Int {
    return image.width
  }

  /// The height of the texture in pixels.
  public var height: Int {
    return image.height
  }

  /// The texture's type.
  public var type: TextureType
  /// The image representation.
  public var image: Image<BGRA<UInt8>>
  /// The animation to use when rendering this texture.
  public var animation: Animation?

  /// The pixel format used by Apple devices.
  public struct BGRA<Channel> {
    var blue: Channel
    var green: Channel
    var red: Channel
    var alpha: Channel
  }

  /// Loads a texture.
  /// - Parameters:
  ///   - pngFile: The png file containing the texture.
  ///   - type: The type of the texture. Calculated if not specified.
  ///   - targetWidth: Scales the image to this width.
  ///   - checkDimensions: If `true`, the texture's width must be a power of two, and the height must be a multiple of the width.
  ///                      `targetWidth` must also be a power of two if present.
  public init(
    pngFile: URL,
    type: TextureType? = nil,
    scaledToWidth targetWidth: Int? = nil,
    checkDimensions: Bool = false
  ) throws {
    let image = try Image<RGBA<UInt8>>(fromPNGFile: pngFile)
    try self.init(
      image: image,
      type: type,
      scaledToWidth: targetWidth,
      checkDimensions: checkDimensions
    )
  }

  /// Loads a texture.
  /// - Parameters:
  ///   - image: The image containing the texture.
  ///   - type: The type of the texture. Calculated if not specified.
  ///   - targetWidth: Scales the image to this width.
  ///   - checkDimensions: If `true`, the texture's width must be a power of two, and the height must be a multiple of the width.
  ///                      `targetWidth` must also be a power of two if present.
  public init(
    image: Image<RGBA<UInt8>>,
    type: TextureType? = nil,
    scaledToWidth targetWidth: Int? = nil,
    checkDimensions: Bool = false
  ) throws {
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

    let width = scaleFactor * image.width
    let height = scaleFactor * image.height

    let resized = image.resizedTo(
      width: width,
      height: height,
      interpolatedBy: .nearestNeighbor
    )

    // BGRA is more efficient for Apple GPUs apparently so we convert all textures to that
    let pixelCount = width * height
    let pixels = [BGRA<UInt8>](unsafeUninitializedCapacity: pixelCount) { buffer, count in
      resized.withUnsafeBufferPointer { pixels in
        for i in 0..<pixelCount {
          let pixel = pixels[i]
          buffer[i] = BGRA<UInt8>(
            blue: pixel.blue,
            green: pixel.green,
            red: pixel.red,
            alpha: pixel.alpha
          )
        }
      }
      count = pixelCount
    }

    self.image = Image(width: resized.width, height: resized.height, pixels: pixels)

    self.type = type ?? Self.typeOfTexture(self.image)
  }

  /// Accesses the pixel at the given coordinates in the image and crashes if the coordinates are
  /// out of bounds.
  public subscript(_ x: Int, _ y: Int) -> BGRA<UInt8> {
    get {
      image[x, y]
    }
    set {
      image[x, y] = newValue
    }
  }

  /// Loads a texture animation from a json file in a resource pack, and then sets is as this texture's animation
  /// - Parameter animationMetadataFile: The animation descriptor file.
  public mutating func setAnimation(file animationMetadataFile: URL) throws {
    let numFrames = height / width
    do {
      let data = try Data(contentsOf: animationMetadataFile)
      let animationMCMeta = try CustomJSONDecoder().decode(AnimationMCMeta.self, from: data)
      animation = Animation(from: animationMCMeta, maxFrameIndex: numFrames)
    } catch {
      throw TextureError.failedToLoadTextureAnimation(error)
    }
  }

  /// Fixes the colour values of transparent pixels to vaguely represent the colours of the pixels around them to help with mipmapping.
  /// This function is probably really slow, I haven't checked yet. Nope, it doesn't seem to be too slow.
  public mutating func fixTransparentPixels() {
    let width = image.width
    let height = image.height

    func index(_ x: Int, _ y: Int) -> Int {
      return x + y * width
    }

    image.withUnsafeMutableBufferPointer { pixels in
      for x in 0..<width {
        // For each transparent pixel copy the color values from above
        for y in 0..<height {
          var pixel = pixels[index(x, y)]
          if pixel.alpha == 0 && y != 0 {
            pixel = pixels[index(x, y - 1)]
            pixel.alpha = 0
            pixels[index(x, y)] = pixel
          }
        }

        // Do the same but the other way
        for y in 1...height {
          let y = height - y
          var pixel = pixels[index(x, y)]
          if pixel.alpha == 0 && y != height - 1 {
            pixel = pixels[index(x, y + 1)]
            pixel.alpha = 0
            pixels[index(x, y)] = pixel
          }
        }
      }

      // Do the whole thing again but horizontally
      for y in 0..<height {
        // For each transparent pixel copy the color values from the left
        for x in 0..<width {
          var pixel = pixels[index(x, y)]
          if pixel.alpha == 0 && x != 0 {
            pixel = pixels[index(x - 1, y)]
            pixel.alpha = 0
            pixels[index(x, y)] = pixel
          }
        }

        // Do the same but the other way
        for x in 1...width {
          let x = width - x
          var pixel = pixels[index(x, y)]
          if pixel.alpha == 0 && x != width - 1 {
            pixel = pixels[index(x + 1, y)]
            pixel.alpha = 0
            pixels[index(x, y)] = pixel
          }
        }
      }
    }
  }

  /// Sets the alpha components of the texutre to a specified value. Alpha value is bound to a range (0...255 inclusive).
  public mutating func setAlpha(_ alpha: UInt8) {
    let clampedAlpha = min(max(alpha, 0), 255)
    let pixelCount = image.width * image.height
    image.withUnsafeMutableBufferPointer { pixels in
      for i in 0..<pixelCount {
        pixels[i].alpha = clampedAlpha
      }
    }
  }

  /// Finds the type of a texture by inspecting its pixels.
  private static func typeOfTexture(
    _ image: Image<BGRA<UInt8>>
  ) -> TextureType {
    var type = TextureType.opaque

    let width = image.width
    let height = image.height
    image.withUnsafeBufferPointer { pixels in
      outer: for x in 0..<width {
        for y in 0..<height {
          let alpha = pixels[x + y * width].alpha

          if alpha == 0 {
            type = .transparent
            // We don't break here because it can still be overidden by translucent
          } else if alpha < 255 {
            type = .translucent
            break outer
          }
        }
      }
    }

    return type
  }
}
