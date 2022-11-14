import CryptoSwift

/// An AES-128-CFB8 stream cipher used for encryption and decryption in the network protocol.
public class Cipher {
  /// The operation that a cipher is made to perform.
  public enum Operation {
    case encrypt
    case decrypt
  }

  /// The cipher's mode of operation.
  public var operation: Operation

  /// The cipher's internal AES encryptor or decryptor.
  private var cryptor: Cryptor & Updatable

  /// Creates a new cipher.
  /// - Parameters:
  ///   - key: The key. Must be at least 16 bytes.
  ///   - iv: The initial vector. Must be at least 16 bytes.
  /// - Precondition: Key must be at least 16 bytes and iv must be at least 16 bytes.
  public init(_ operation: Operation, key: [UInt8], iv: [UInt8]) throws {
    precondition(key.count >= 16, "Key must be at least 16 bytes, was \(key.count)")
    precondition(iv.count >= 16, "IV must be at least 16 bytes, was \(iv.count)")

    self.operation = operation

    let aes = try AES(
      key: key,
      blockMode: CFB(iv: iv, segmentSize: .cfb8),
      padding: .noPadding
    )

    switch operation {
      case .encrypt:
        cryptor = try aes.makeEncryptor()
      case .decrypt:
        cryptor = try aes.makeDecryptor()
    }
  }

  public func update(with bytes: [UInt8]) throws -> [UInt8] {
    let new = try cryptor.update(withBytes: bytes)
    return new
  }
}
