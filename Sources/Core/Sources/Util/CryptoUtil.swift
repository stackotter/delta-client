import Foundation
import OpenSSL

enum CryptoError: LocalizedError {
  case failedToGenerateSharedSecret
  case invalidDERCertificate
  case failedToEncryptRSA
  case failedToInitializeSHA1
  case failedToUpdateSHA1
  case failedToFinalizeSHA1
  case failedToParseDERPublicKey

  var errorDescription: String? {
    switch self {
      case .failedToGenerateSharedSecret:
        return "Failed to generate shared secret."
      case .invalidDERCertificate:
        return "Invalid DER certificate."
      case .failedToEncryptRSA:
        return "Failed to encrypt RSA."
      case .failedToInitializeSHA1:
        return "Failed to initialize SHA1."
      case .failedToUpdateSHA1:
        return "Failed to update SHA1 hash."
      case .failedToFinalizeSHA1:
        return "Failed to finalize SHA1 hash."
      case .failedToParseDERPublicKey:
        return "Failed to parse DER-encoded RSA public key."
    }
  }
}

// TODO: Implement tests for CryptoUtil, it should be very testable

struct CryptoUtil {
  static func generateSharedSecret(_ length: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = RAND_bytes(&bytes, Int32(length))
    if status != 1 {
      throw CryptoError.failedToGenerateSharedSecret
    }
    return bytes
  }

  static func sha1MojangDigest(_ contents: [Data]) throws -> String {
    var ctx = SHA_CTX()
    if SHA1_Init(&ctx) != 1 {
      throw CryptoError.failedToInitializeSHA1
    }

    for data in contents {
      if data.withUnsafeBytes({ pointer in
        return SHA1_Update(&ctx, pointer.baseAddress, contents.count)
      }) != 1 {
        throw CryptoError.failedToUpdateSHA1
      }
    }

    var digest = [UInt8](repeating: 0, count: Int(SHA_DIGEST_LENGTH))
    if SHA1_Final(&digest, &ctx) != 1 {
      throw CryptoError.failedToFinalizeSHA1
    }

    // Do some weird stuff to convert to a signed hex string without doing biginteger stuff
    var isNegative = false

    let firstBit = (digest[0] & 0x80) >> 7
    isNegative = firstBit == 1

    let hexStrings: [String] = digest.enumerated().map { index, inByte in
      var byte = inByte
      if isNegative {
        byte = 255 - byte
      }
      if index == 19 && isNegative { // last byte
        byte += 1
      }
      return String(format: "%02x", byte)
    }
    var string = isNegative ? "-" : ""
    string += hexStrings.joined()
    return string
  }

  static func rsaCipher(fromPublicKey publicKeyDERData: Data) throws -> RSA {
    guard let keyPointer: UnsafeMutablePointer<RSA> = publicKeyDERData.withUnsafeBytes({ (pointer: UnsafeRawBufferPointer) in
      var dataPointer = pointer.bindMemory(to: UInt8.self).baseAddress
      let rsa: UnsafeMutablePointer<RSA>? = d2i_RSAPublicKey(nil, &dataPointer, publicKeyDERData.count)
      return rsa
    }) else {
      throw CryptoError.failedToParseDERPublicKey
    }

    return keyPointer.pointee
  }

  static func encryptRSA(data: Data, publicKeyDERData: Data) throws -> Data {
    var rsa = try rsaCipher(fromPublicKey: publicKeyDERData)
    var inBytes = [UInt8](data)
    var outBytes = [UInt8](repeating: 0, count: data.count)
    if RSA_public_encrypt(Int32(data.count), &inBytes, &outBytes, &rsa, RSA_PKCS1_PADDING) != 1 {
      throw CryptoError.failedToEncryptRSA
    }
    return Data(bytes: outBytes, count: outBytes.count)
  }
}
