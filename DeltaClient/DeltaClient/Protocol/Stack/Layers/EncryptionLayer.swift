//
//  EncryptionLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import CryptoSwift
import os

class EncryptionLayer: NetworkLayer {
  var inputCryptor: (Cryptor & Updatable)?
  var outputCryptor: (Cryptor & Updatable)?
  
  var inboundSuccessor: InboundNetworkLayer?
  var outboundSuccessor: OutboundNetworkLayer?
  
  func createCipher(sharedSecret: [UInt8]) throws -> AES {
    return try AES(
      key: sharedSecret,
      blockMode: CFB(iv: sharedSecret, segmentSize: .cfb8),
      padding: .noPadding
    )
  }
  
  func enableEncryption(sharedSecret: [UInt8]) throws {
    let cipher = try createCipher(sharedSecret: sharedSecret)
    inputCryptor = try cipher.makeDecryptor()
    outputCryptor = try cipher.makeEncryptor()
    Logger.debug("enabled encryption")
  }
  
  func handleInbound(_ buffer: Buffer) {
    if inputCryptor != nil {
      do {
        var decrypted = Array<UInt8>()
        decrypted.reserveCapacity(buffer.bytes.count)
        for byte in buffer.bytes {
          decrypted += try inputCryptor!.update(withBytes: [byte])
        }
        inboundSuccessor?.handleInbound(Buffer(decrypted))
      } catch {
        Logger.error("failed to decrypt packet: \(error)")
      }
    }
    else {
      inboundSuccessor?.handleInbound(buffer)
    }
  }
  
  func handleOutbound(_ buffer: Buffer) {
    if outputCryptor != nil {
      do {
        var encrypted = Array<UInt8>()
        encrypted.reserveCapacity(buffer.bytes.count)
        for byte in buffer.bytes {
          encrypted += try outputCryptor!.update(withBytes: [byte])
        }
        outboundSuccessor?.handleOutbound(Buffer(encrypted))
      } catch {
        Logger.error("failed to encrypt packet: \(error)")
      }
    }
    else {
      outboundSuccessor?.handleOutbound(buffer)
    }
  }
}
