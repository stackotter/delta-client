import Foundation
import Compression

struct CompressionUtil {
  static func decompress(_ bytes: [UInt8], decompressedLength: Int) -> [UInt8] {
    let compressedData = Data(bytes: bytes, count: bytes.count)
    
    /*
     decompression only works if the first two bytes are removed
     no idea why, it's probably something to do with headers or magic numbers
    */
    var compressedBytes = [UInt8](compressedData[2...])
    
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressedLength)
    let length = compression_decode_buffer(
      buffer,
      decompressedLength,
      &compressedBytes,
      compressedBytes.count,
      nil,
      COMPRESSION_ZLIB)
    
    if length != decompressedLength {
      log.warning("actual decompressed length does not match length in packet")
    }
    
    let data = Data(bytes: buffer, count: length)
    buffer.deallocate()
    return [UInt8](data)
  }
  
  static func compress(_ bytes: [UInt8]) -> [UInt8] {
    var uncompressed = bytes // mutable copy
    let compressed = UnsafeMutablePointer<UInt8>.allocate(capacity: uncompressed.count)
    let compressedLength = compression_encode_buffer(
      compressed,
      uncompressed.count,
      &uncompressed,
      uncompressed.count,
      nil,
      COMPRESSION_ZLIB)
    
    let data = Data(bytes: compressed, count: compressedLength)
    return [UInt8](data)
  }
}
