//
//  CompressionUtil.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation
import Compression

struct CompressionUtil {
  static func decompress(_ bytes: [UInt8], decompressedLength: Int) -> [UInt8] {
    let compressedData = Data(bytes: bytes, count: bytes.count)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompressedLength)
    
    let length = compressedData[2...].withUnsafeBytes {
      compression_decode_buffer(buffer, decompressedLength, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1), compressedData.count - 2, nil, COMPRESSION_ZLIB)
    }
    
    let data = Data(bytes: buffer, count: length)
    buffer.deallocate()
    return [UInt8](data)
  }
  
  static func compress(_ bytes: [UInt8]) -> [UInt8] {
    var uncompressed = bytes // mutable copy
    let compressed = UnsafeMutablePointer<UInt8>.allocate(capacity: uncompressed.count)
    let compressedLength = compression_encode_buffer(compressed, uncompressed.count, &uncompressed, uncompressed.count, nil, COMPRESSION_ZLIB)
    let data = Data(bytes: compressed, count: compressedLength)
    return [UInt8](data)
  }
}
