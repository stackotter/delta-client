import Foundation
import Compression

public class CompressionLayer: NetworkLayer {
  public var inboundSuccessor: InboundNetworkLayer?
  public var outboundSuccessor: OutboundNetworkLayer?
  
  public var compressionThreshold = -1
  
  public func handleInbound(_ inBuffer: Buffer) {
    if compressionThreshold > 0 {
      var buffer = inBuffer // mutable copy
      let dataLength = buffer.readVarInt()
      if dataLength == 0 { // uncompressed packet
        inboundSuccessor?.handleInbound(buffer)
      } else { // compressed packet
        if dataLength < compressionThreshold {
          log.error("illegal compressed packet received (below compression threshold), threshold: \(compressionThreshold), length: \(dataLength)")
          let compressedBytes = buffer.readRemainingBytes()
          let decompressed = CompressionUtil.decompress(compressedBytes, decompressedLength: dataLength)
          inboundSuccessor?.handleInbound(Buffer(decompressed))
        } else {
          let compressedBytes = buffer.readRemainingBytes()
          let decompressed = CompressionUtil.decompress(compressedBytes, decompressedLength: dataLength)
          inboundSuccessor?.handleInbound(Buffer(decompressed))
        }
      }
    } else {
      inboundSuccessor?.handleInbound(inBuffer)
    }
  }
  
  public func handleOutbound(_ inBuffer: Buffer) {
    if compressionThreshold > 0 { // compression enabled
      var buffer = inBuffer // mutable copy
      var outBuffer = Buffer()
      if buffer.length >= compressionThreshold {
        let bytes = buffer.readRemainingBytes()
        let compressed = CompressionUtil.compress(bytes)
        outBuffer.writeVarInt(Int32(compressed.count))
        outBuffer.writeBytes(compressed)
        outboundSuccessor?.handleOutbound(outBuffer)
      } else {
        outBuffer.writeVarInt(0)
        outBuffer.writeBytes(buffer.readRemainingBytes())
        outboundSuccessor?.handleOutbound(outBuffer)
      }
    } else { // compression disabled
      outboundSuccessor?.handleOutbound(inBuffer)
    }
  }
}
