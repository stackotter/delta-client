//
//  CryptoUtil.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 7/4/21.
//

import Foundation
import CryptoKit

enum CryptoError: LocalizedError {
  case failedToGenerateSharedSecret
  case invalidDERCertificate
  case failedToEncryptRSA
}

struct CryptoUtil {
  static func generateSharedSecret(_ length: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    if status != errSecSuccess {
      throw CryptoError.failedToGenerateSharedSecret
    }
    return bytes
  }
  
  static func sha1MojangDigest(_ contents: [Data]) -> String {
    var sha1 = Insecure.SHA1()
    for data in contents {
      sha1.update(data: data)
    }
    let digest = sha1.finalize()
    
    // do some weird stuff to convert to a signed hex string without doing biginteger stuff
    var isNegative = false
    digest.withUnsafeBytes {
      let firstByte = $0.load(as: UInt8.self)
      let firstBit = (firstByte & 0x80) >> 7
      isNegative = firstBit == 1
    }
    
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
  
  static func publicKeyRSA(derData: Data) throws -> SecKey {
    let attributes: [CFString: Any] = [
      kSecAttrKeyClass: kSecAttrKeyClassPublic,
      kSecAttrKeyType: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits: 1024
    ]
    
    guard let key = SecKeyCreateFromData(attributes as CFDictionary, derData as NSData, nil) else {
      throw CryptoError.invalidDERCertificate
    }
    return key
  }
  
  static func encryptRSA(data: Data, publicKeyDERData: Data) throws -> Data {
    let key = try publicKeyRSA(derData: publicKeyDERData)
    
    var error: Unmanaged<CFError>?
    guard let encrypted = SecKeyCreateEncryptedData(key, .rsaEncryptionPKCS1, data as CFData, &error) else {
      throw CryptoError.failedToEncryptRSA
    }
    return encrypted as Data
  }
}
