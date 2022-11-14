import Foundation

/// An error related to packet encryption and decryption.
public enum EncryptionLayerError: LocalizedError {
  /// Failed to decrypt a packet.
  case failedToDecryptPacket(Error)
  /// Failed to encrypt a packet.
  case failedToEncryptPacket(Error)

  public var errorDescription: String? {
    switch self {
      case .failedToDecryptPacket(let error):
        return """
        Failed to decrypt a packet.
        Reason: \(error.localizedDescription)
        """
      case .failedToEncryptPacket(let error):
        return """
        Failed to encrypt a packet.
        Reason: \(error.localizedDescription)
        """
    }
  }
}

/// Handles the encryption and decryption of packets (outbound and inbound respectively).
public struct EncryptionLayer {
  // MARK: Private properties

  /// The cipher used for decrypting inbound packets.
  private var inputCipher: Cipher?
  /// The cipher used for encryption outbound packets.
  private var outputCipher: Cipher?

  // MARK: Init

  /// Creates a new encryption layer.
  public init() {}

  // MARK: Public methods

  /// Enables the encryption layer.
  /// - Parameter sharedSecret: The shared secret to initialize the stream ciphers with.
  public mutating func enableEncryption(sharedSecret: [UInt8]) throws {
    inputCipher = try Cipher(.decrypt, key: sharedSecret, iv: sharedSecret)
    outputCipher = try Cipher(.encrypt, key: sharedSecret, iv: sharedSecret)
  }

  /// Decrypts a packet.
  public func processInbound(_ buffer: Buffer) throws -> Buffer {
    if let cipher = inputCipher {
      do {
        let decrypted = try cipher.update(with: buffer.bytes)
        return Buffer(decrypted)
      } catch {
        throw EncryptionLayerError.failedToDecryptPacket(error)
      }
    } else {
      return buffer
    }
  }

  /// Encrypts a packet.
  public func processOutbound(_ buffer: Buffer) throws -> Buffer {
    if let cipher = outputCipher {
      do {
        let encrypted = try cipher.update(with: buffer.bytes)
        return Buffer(encrypted)
      } catch {
        throw EncryptionLayerError.failedToEncryptPacket(error)
      }
    } else {
      return buffer
    }
  }
}
