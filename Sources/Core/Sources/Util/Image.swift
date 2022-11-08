import Foundation
import SwiftImage
import PNG

public enum ImageError: LocalizedError {
  case failedToReadPNGFile

  public var errorDescription: String? {
    switch self {
      case .failedToReadPNGFile:
        return "Failed to read PNG file."
    }
  }
}

extension Image where Pixel == SwiftImage.RGBA<UInt8> {
  init(fromPNGFile file: URL) throws {
    guard let image = try PNG.Data.Rectangular.decompress(path: file.path) else {
      throw ImageError.failedToReadPNGFile
    }

    let pngPixels = image.unpack(as: PNG.RGBA<UInt8>.self)
    let pixels = Array(unsafeUninitializedCapacity: pngPixels.count) { buffer, count in
      for (i, pixel) in pngPixels.enumerated() {
        buffer[i] = SwiftImage.RGBA<UInt8>(
          red: pixel.r,
          green: pixel.g,
          blue: pixel.b,
          alpha: pixel.a
        )
      }
      count = pngPixels.count
    }
    self.init(width: image.size.x, height: image.size.y, pixels: pixels)
  }
}

