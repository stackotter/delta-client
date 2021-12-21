import Foundation
import IDZSwiftCommonCrypto

/// An error related to packet encryption and decryption.
public enum EncryptionLayerError: LocalizedError {
  /// Failed to decrypt a packet.
  case failedToDecryptPacket(Status)
  /// Failed to encrypt a packet.
  case failedToEncryptPacket(Status)
}

/// Handles the encryption and decryption of packets (outbound and inbound respectively).
public struct EncryptionLayer {
  // MARK: Private properties
  
  /// The cryptor used for decrypting inbound packets.
  private var inputCryptor: StreamCryptor?
  /// The cryptor used for encryption outbound packets.
  private var outputCryptor: StreamCryptor?
  
  // MARK: Init
  
  /// Creates a new encryption layer.
  public init() {}
  
  // MARK: Public methods
  
  /// Enables the encryption layer.
  /// - Parameter sharedSecret: The shared secret to initialize the stream cryptors with.
  public mutating func enableEncryption(sharedSecret: [UInt8]) {
    inputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .decrypt)
    outputCryptor = createCryptor(sharedSecret: sharedSecret, operation: .encrypt)
  }
  
  /// Decrypts a packet.
  public func processInbound(_ buffer: Buffer) throws -> Buffer {
    if let cryptor = inputCryptor {
      var decrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &decrypted)
      if status == .success {
        return Buffer(decrypted)
      } else {
        throw EncryptionLayerError.failedToDecryptPacket(status)
      }
    } else {
      return buffer
    }
  }
  
  /// Encrypts a packet.
  public func processOutbound(_ buffer: Buffer) throws -> Buffer {
    if let cryptor = outputCryptor {
      var encrypted = [UInt8](repeating: 0, count: buffer.bytes.count)
      let (_, status) = cryptor.update(byteArrayIn: buffer.bytes, byteArrayOut: &encrypted)
      if status == .success {
        return Buffer(encrypted)
      } else {
        throw EncryptionLayerError.failedToEncryptPacket(status)
      }
    } else {
      return buffer
    }
  }
  
  // MARK: Private methods
  
  /// Creates a stream cryptor.
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
