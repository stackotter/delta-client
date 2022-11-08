import Foundation
import Z

enum CompressionError: LocalizedError {
  case compressionFailed(error: Int)
  case decompressionFailed(error: Int)

  var errorDescription: String? {
    switch self {
      case .compressionFailed(let error):
        return """
        Zlib compression failed.
        Error code: \(error)
        """
      case .decompressionFailed(let error):
        return """
        Zlib decompression failed.
        Error code: \(error)
        """
    }
  }
}

struct CompressionUtil {
  static func decompress(_ bytes: [UInt8], decompressedLength: Int) throws -> [UInt8] {
    let compressedData = Data(bytes: bytes, count: bytes.count)

    // Decompression only works if the first two bytes are removed no idea why, it's probably
    // something to do with headers or magic numbers
    var compressedBytes = [UInt8](compressedData)

    var length = UInt(decompressedLength)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressedLength)
    let err = Z.uncompress(
      buffer,
      &length,
      &compressedBytes,
      UInt(compressedBytes.count)
    )

    if err != Z_OK {
      throw CompressionError.decompressionFailed(error: Int(err))
    }

    if length != decompressedLength {
      log.warning("actual decompressed length does not match length in packet")
    }

    let data = Data(bytes: buffer, count: Int(length))
    buffer.deallocate()
    return [UInt8](data)
  }

  static func compress(_ bytes: [UInt8]) throws -> [UInt8] {
    var uncompressed = bytes // mutable copy
    let compressed = UnsafeMutablePointer<UInt8>.allocate(capacity: uncompressed.count)
    var compressedLength = UInt(uncompressed.count)
    let err = Z.compress(
      compressed,
      &compressedLength,
      &uncompressed,
      UInt(uncompressed.count)
    )

    if err != Z_OK {
      throw CompressionError.compressionFailed(error: Int(err))
    }

    let data = Data(bytes: compressed, count: Int(compressedLength))
    return [UInt8](data)
  }
}
