import OpenSSL

/// An AES-128-CFB8 stream cipher used for encryption and decryption in the network protocol.
public class Cipher {
  /// The operation that a cipher is made to perform.
  public enum Operation {
    case encrypt
    case decrypt
  }

  /// The cipher's purpose.
  public var operation: Operation

  /// The cipher context.
  private var context: UnsafeMutablePointer<EVP_CIPHER_CTX>

  /// Creates a new cipher.
  /// - Parameters:
  ///   - key: The key. Must be at least 16 bytes.
  ///   - iv: The initial vector. Must be at least 16 bytes.
  /// - Precondition: Key must be at least 16 bytes and iv must be at least 16 bytes.
  public init(_ operation: Operation, key: [UInt8], iv: [UInt8]) throws {
    assert(key.count >= 16, "Key must be at least 16 bytes, was \(key.count)")
    assert(iv.count >= 16, "IV must be at least 16 bytes, was \(iv.count)")

    guard let context = EVP_CIPHER_CTX_new() else {
      throw EncryptionLayerError.failedToInitializeCipher
    }
    self.context = context
    self.operation = operation

    let returnCode: Int32
    switch operation {
      case .encrypt:
        returnCode = EVP_EncryptInit_ex(self.context, EVP_aes_128_cfb8(), nil, key, iv)
      case .decrypt:
        returnCode = EVP_DecryptInit_ex(self.context, EVP_aes_128_cfb8(), nil, key, iv)
    }

    if 1 != returnCode {
      EVP_CIPHER_CTX_free(self.context)
      throw EncryptionLayerError.failedToInitializeCipher
    }
  }

  deinit {
    EVP_CIPHER_CTX_free(context)
  }

  public func update(with bytes: [UInt8]) throws -> [UInt8] {
    let output = try [UInt8](unsafeUninitializedCapacity: bytes.count) { buffer, count in
      var bytes = bytes
      var length: Int32 = 0
      guard var pointer = buffer.baseAddress else {
        throw EncryptionLayerError.failedToCreateUninitializedBuffer
      }
      for i in 0..<bytes.count {
        let returnCode: Int32
        switch operation {
          case .encrypt:
            returnCode = EVP_EncryptUpdate(context, pointer, &length, &bytes[i], 1)
          case .decrypt:
            returnCode = EVP_DecryptUpdate(context, pointer, &length, &bytes[i], 1)
        }
        if 1 != returnCode {
          throw EncryptionLayerError.failedToUpdateCipher
        }
        count += Int(length)
        pointer = pointer.advanced(by: 1)
      }
    }
    return output
  }
}
