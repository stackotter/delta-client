//
//  EncryptionLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import IDZSwiftCommonCrypto


class EncryptionLayer: NetworkLayer {
  var inputCryptor: StreamCryptor?
  var outputCryptor: StreamCryptor?
  
  var inboundSuccessor: InboundNetworkLayer?
  var outboundSuccessor: OutboundNetworkLayer?
  
  func createCryptor(sharedSecret: [UInt8], operation: StreamCryptor.Operation) -> StreamCryptor {
    return StreamCryptor(
      operation: operation,
      algorithm: .aes,
      mode: .CFB8,
      padding: .NoPadding,
      key: sharedSecret,
      iv: sharedSecret
    )
  }
  
  func enableEncryption(sharedSecret: [UInt8]) {
    inputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .decrypt)
    outputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .encrypt)
    Logger.debug("enabled encryption")
  }
  
  func handleInbound(_ buffer: Buffer) {
    if let cryptor = inputCryptor {
      var decrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &decrypted)
      if status == .success {
        inboundSuccessor?.handleInbound(Buffer(decrypted))
      } else {
        Logger.error("failed to decrypt packet: \(status)")
      }
    } else {
      inboundSuccessor?.handleInbound(buffer)
    }
  }
  
  func handleOutbound(_ buffer: Buffer) {
    if let cryptor = outputCryptor {
      var encrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &encrypted)
      if status == .success {
        outboundSuccessor?.handleOutbound(Buffer(encrypted))
      } else {
        Logger.error("failed to decrypt packet: \(status)")
      }
    } else {
      outboundSuccessor?.handleOutbound(buffer)
    }
  }
}
