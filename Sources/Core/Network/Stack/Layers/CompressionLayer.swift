import Foundation
import Compression

/// An error with packet compression.
public enum CompressionLayerError: LocalizedError {
  /// A compressed packet was under the required length for compressed packets.
  case compressedPacketIsUnderThreshold(length: Int, threshold: Int)
}

/// Handles the compression and decompression of packets (outbound and inbound respectively).
public struct CompressionLayer {
  // MARK: Public properties
  
  /// Packets greater than or equal to this threshold (in length) will get compressed.
  public var compressionThreshold = -1
  
  // MARK: Init
  
  /// Creates a new compression layer.
  public init() {}
  
  // MARK: Public properties
  
  public func processInbound(_ buffer: Buffer) throws -> Buffer {
    if compressionThreshold > 0 {
      var buffer = buffer
      let dataLength = Int(try buffer.readVariableLengthInteger())
      if dataLength == 0 { // Packet isn't compressed
        return buffer
      } else { // Packet is compressed
        if dataLength < compressionThreshold {
          throw CompressionLayerError.compressedPacketIsUnderThreshold(length: dataLength, threshold: compressionThreshold)
        } else {
          let compressedBytes = buffer.readRemainingBytes()
          let decompressed = CompressionUtil.decompress(compressedBytes, decompressedLength: dataLength)
          return Buffer(decompressed)
        }
      }
    } else {
      return buffer
    }
  }
  
  public func processOutbound(_ buffer: Buffer) -> Buffer {
    if compressionThreshold > 0 { // Compression is enabled
      var buffer = buffer
      var outBuffer = Buffer()
      if buffer.length >= compressionThreshold {
        let bytes = buffer.readRemainingBytes()
        let compressed = CompressionUtil.compress(bytes)
        outBuffer.writeVarInt(Int32(compressed.count))
        outBuffer.writeBytes(compressed)
        return outBuffer
      } else {
        outBuffer.writeVarInt(0)
        outBuffer.writeBytes(buffer.readRemainingBytes())
        return outBuffer
      }
    } else { // Compression is disabled
      return buffer
    }
  }
}
