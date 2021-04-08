//
//  AESCFB8StreamCryptor.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import Foundation
import CryptoSwift

//extension AES {
//  public func decryptPublic(block: ArraySlice<UInt8>) -> ArraySlice<UInt8> {
//    self.de
//  }
//}
//
//class AESCFB8StreamCryptor {
//  let iv: ArraySlice<UInt8>
//  let key: ArraySlice<UInt8>
//
//  var prev: ArraySlice<UInt8>
//
//  let cipher: AES
//
//  init(iv: [UInt8], key: [UInt8]) throws {
//    self.cipher = try AES(
//      key: key,
//      blockMode: CFB(iv: iv, segmentSize: .cfb8),
//      padding: .noPadding
//    )
//    self.iv = ArraySlice<UInt8>(iv)
//    self.key = ArraySlice<UInt8>(key)
//  }
//
//  func decrypt(cipherByte: UInt8) -> UInt8 {
//    guard let plaintext = cipher.encrypt(prev ?? iv) else {
//      return cipherByte
//    }
//    self.prev = Array((prev ?? iv).dropFirst()) + [cipherByte]
//    return [cipherByte ^ Array(plaintext)[0]]
//  }
//}
