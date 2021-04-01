//
//  CompressionLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import Compression
import os

class CompressionLayer: NetworkLayer {
  var inboundSuccessor: InboundNetworkLayer?
  var outboundSuccessor: OutboundNetworkLayer?
  var compressionThreshold = -1
  
  func handleInbound(_ inBuffer: Buffer) {
    if compressionThreshold > 0 {
      var buffer = inBuffer // mutable copy
      let dataLength = buffer.readVarInt()
      if dataLength == 0 { // uncompressed packet
        inboundSuccessor?.handleInbound(buffer)
      } else { // compressed packet
        if dataLength < compressionThreshold {
          Logger.error("illegal compressed packet received (below compression threshold)")
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
  
  func handleOutbound(_ inBuffer: Buffer) {
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
