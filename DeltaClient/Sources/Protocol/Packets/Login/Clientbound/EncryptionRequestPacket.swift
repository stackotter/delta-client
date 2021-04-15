//
//  EncryptionRequestPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation
import os

struct EncryptionRequestPacket: ClientboundPacket {
  static let id: Int = 0x01
  
  var serverId: String
  var publicKey: [UInt8]
  var verifyToken: [UInt8]

  init(from packetReader: inout PacketReader) throws {
    serverId = packetReader.readString()
    
    let publicKeyLength = packetReader.readVarInt()
    publicKey = packetReader.readByteArray(length: publicKeyLength)
    
    let verifyTokenLength = packetReader.readVarInt()
    verifyToken = packetReader.readByteArray(length: verifyTokenLength)
  }
  
  func handle(for server: Server) throws {
    let sharedSecret = try CryptoUtil.generateSharedSecret(16)
    
    // send request to mojang api to join game
    let serverHash = CryptoUtil.sha1MojangDigest([
      serverId.data(using: .ascii)!,
      Data(sharedSecret),
      Data(publicKey)
    ])
    
    let configManager = server.managers.configManager
    if let account = configManager!.getSelectedAccount() {
      let accessToken = account.accessToken
      let selectedProfile = configManager!.getSelectedProfile()!.id
      MojangAPI.join(accessToken: accessToken, selectedProfile: selectedProfile, serverHash: serverHash, completion: {
        // block inbound thread until encryption is enabled
        server.connection.networkStack.inboundThread.sync {
          do {
            // send encryption response packet
            let publicKeyData = Data(publicKey)
            let encryptedSharedSecret = try CryptoUtil.encryptRSA(data: Data(sharedSecret), publicKeyDERData: publicKeyData)
            let encryptedVerifyToken = try CryptoUtil.encryptRSA(data: Data(verifyToken), publicKeyDERData: publicKeyData)
            let encryptionResponse = EncryptionResponsePacket(
              sharedSecret: [UInt8](encryptedSharedSecret),
              verifyToken: [UInt8](encryptedVerifyToken)
            )
            server.sendPacket(encryptionResponse)
            
            // wait for packet to send then enable encryption
            server.connection.networkStack.outboundThread.sync {
              server.connection.enableEncryption(sharedSecret: sharedSecret)
            }
          } catch {
            Logger.error("failed to enable encryption: \(error)")
          }
        }
      })
    } else {
      Logger.error("not logged in")
      DeltaClientApp.triggerError("failed to join server: not logged in")
      return
    }
  }
}
