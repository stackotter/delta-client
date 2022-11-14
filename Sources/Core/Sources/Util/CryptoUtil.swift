import Foundation
import ASN1Parser
import BigInt
import CryptoSwift

enum CryptoError: LocalizedError {
  case invalidDERCertificate
  case failedToEncryptRSA
  case failedToParseDERPublicKey(Error)
  case plaintextTooLong

  var errorDescription: String? {
    switch self {
      case .invalidDERCertificate:
        return "Invalid DER certificate."
      case .failedToEncryptRSA:
        return "Failed to encrypt RSA."
      case .failedToParseDERPublicKey(let error):
        return """
        Failed to parse DER-encoded RSA public key.
        Reason: \(error)
        """
      case .plaintextTooLong:
        return "The plaintext provided for RSA encryption was too long."
    }
  }
}

// TODO: Implement tests for CryptoUtil, it should be very testable

struct CryptoUtil {
  static func generateRandomBytes(_ length: Int) throws -> [UInt8] {
    return AES.randomIV(length)
  }

  static func sha1MojangDigest(_ contents: [Data]) throws -> String {
    var digest = SHA1()
    for data in contents {
      _ = try digest.update(withBytes: [UInt8](data))
    }
    let bytes = try digest.finish()

    // Do some weird stuff to convert to a signed hex string without doing biginteger stuff (Mojang
    // uses this weird custom type of hash)
    var isNegative = false

    let firstBit = (bytes[0] & 0x80) >> 7
    isNegative = firstBit == 1

    let hexStrings: [String] = bytes.enumerated().map { index, inByte in
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

  static func generateRSAPadding(_ length: Int) throws -> [UInt8] {
    // TODO: Make a faster version of this maybe (currently it's technically non-deterministic)
    var output: [UInt8] = []
    while output.count < length {
      output.append(contentsOf: try generateRandomBytes(length - output.count))
      output = output.filter { $0 != 0 }
    }
    return output
  }

  /// Implements the padded encryption operation outlined by the
  /// [PKCS1 RFC document](https://datatracker.ietf.org/doc/html/rfc3447#section-7.2.1).
  static func encryptRSA(data: Data, publicKeyDERData: Data) throws -> Data {
    let modulus: BigInt
    let exponent: BigInt
    do {
      let der = try DERParser.parse(der: publicKeyDERData)
      let bitString = try der.asSequence[1].asBitString
      let sequence = try DERParser.parse(der: Data(bitString.bytes)).asSequence

      modulus = try sequence[0].asInt.value // n
      exponent = try sequence[1].asInt.value // e
    } catch {
      throw CryptoError.failedToParseDERPublicKey(error)
    }

    // I've implemented RSA (with PKCS1 padding) myself because OpenSSL hates me (it's mutual)
    let modulusLength = modulus.serialize().count - 1 // k
    guard data.count <= modulusLength - 11 else {
      throw CryptoError.plaintextTooLong
    }

    let plaintext = [UInt8](data)
    let paddingLength = modulusLength - plaintext.count - 3
    let padding = try generateRSAPadding(paddingLength)
    let paddedPlaintextBytes = [0, 2] + padding + [0] + plaintext
    let paddedPlaintext = BigInt(Data(paddedPlaintextBytes))

    let ciphertext = paddedPlaintext.power(exponent, modulus: modulus)
    var ciphertextBytes = [UInt8](ciphertext.serialize())
    if ciphertextBytes[0] == 0 {
      ciphertextBytes.removeFirst()
    }
    if ciphertextBytes.count < modulusLength {
      let cipherPadding = [UInt8](repeating: 0, count: modulusLength - ciphertextBytes.count)
      ciphertextBytes = cipherPadding + ciphertextBytes
    }

    return Data(ciphertextBytes)
  }
}
