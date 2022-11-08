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

    var pngPixels = image.unpack(as: PNG.RGBA<UInt8>.self)
    let pixelCount = pngPixels.count
    let pixels = Swift.withUnsafeBytes(of: &pngPixels) { pointer in
      return Array(UnsafeBufferPointer(
        start: pointer.baseAddress!.assumingMemoryBound(to: SwiftImage.RGBA<UInt8>.self),
        count: pixelCount
      ))
    }
    self.init(width: image.size.x, height: image.size.y, pixels: pixels)
  }
}

