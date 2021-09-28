//
//  EncryptionLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation
import IDZSwiftCommonCrypto

public class EncryptionLayer: NetworkLayer {
  private var inputCryptor: StreamCryptor?
  private var outputCryptor: StreamCryptor?
  
  public var inboundSuccessor: InboundNetworkLayer?
  public var outboundSuccessor: OutboundNetworkLayer?
  
  public func enableEncryption(sharedSecret: [UInt8]) {
    inputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .decrypt)
    outputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .encrypt)
    log.debug("enabled encryption")
  }
  
  public func handleInbound(_ buffer: Buffer) {
    if let cryptor = inputCryptor {
      var decrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &decrypted)
      if status == .success {
        inboundSuccessor?.handleInbound(Buffer(decrypted))
      } else {
        log.error("failed to decrypt packet: \(status)")
      }
    } else {
      inboundSuccessor?.handleInbound(buffer)
    }
  }
  
  public func handleOutbound(_ buffer: Buffer) {
    if let cryptor = outputCryptor {
      var encrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &encrypted)
      if status == .success {
        outboundSuccessor?.handleOutbound(Buffer(encrypted))
      } else {
        log.error("failed to decrypt packet: \(status)")
      }
    } else {
      outboundSuccessor?.handleOutbound(buffer)
    }
  }
  
  private func createCryptor(sharedSecret: [UInt8], operation: StreamCryptor.Operation) -> StreamCryptor {
    return StreamCryptor(
      operation: operation,
      algorithm: .aes,
      mode: .CFB8,
      padding: .NoPadding,
      key: sharedSecret,
      iv: sharedSecret
    )
  }
}
