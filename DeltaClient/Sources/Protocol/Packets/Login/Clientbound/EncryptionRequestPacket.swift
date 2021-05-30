//
//  EncryptionRequestPacket.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 1/4/21.
//

import Foundation

struct EncryptionRequestPacket: ClientboundPacket {
  static let id: Int = 0x01
  
  var serverId: String
  var publicKey: [UInt8]
  var verifyToken: [UInt8]

  init(from packetReader: inout PacketReader) throws {
    serverId = try packetReader.readString()
    
    let publicKeyLength = packetReader.readVarInt()
    publicKey = packetReader.readByteArray(length: publicKeyLength)
    
    let verifyTokenLength = packetReader.readVarInt()
    verifyToken = packetReader.readByteArray(length: verifyTokenLength)
  }
  
  func handle(for server: Server) throws {
    let sharedSecret = try CryptoUtil.generateSharedSecret(16)
    
    guard let serverIdData = serverId.data(using: .ascii) else {
      throw ClientboundPacketError.invalidServerId
    }
    
    // send request to mojang api to join game
    let serverHash = CryptoUtil.sha1MojangDigest([
      serverIdData,
      Data(sharedSecret),
      Data(publicKey)
    ])
    
    // TODO: configmanager should be a singleton
    if let account = server.managers.configManager.getSelectedAccount() {
      if let mojangAccount = account as? MojangAccount {
        let accessToken = mojangAccount.accessToken
        // TODO: when multi accounting is done no force unwrapping should be necessary
        let selectedProfile = account.profileId
        MojangAPI.join(
          accessToken: accessToken,
          selectedProfile: selectedProfile,
          serverHash: serverHash,
          onCompletion: {
            // block inbound thread until encryption is enabled
            server.connection.networkStack.inboundThread.sync {
              do {
                // send encryption response packet
                let publicKeyData = Data(publicKey)
                let encryptedSharedSecret = try CryptoUtil.encryptRSA(
                  data: Data(sharedSecret),
                  publicKeyDERData: publicKeyData)
                let encryptedVerifyToken = try CryptoUtil.encryptRSA(
                  data: Data(verifyToken),
                  publicKeyDERData: publicKeyData)
                let encryptionResponse = EncryptionResponsePacket(
                  sharedSecret: [UInt8](encryptedSharedSecret),
                  verifyToken: [UInt8](encryptedVerifyToken))
                server.sendPacket(encryptionResponse)
                
                // wait for packet to send then enable encryption
                server.connection.networkStack.outboundThread.sync {
                  server.connection.enableEncryption(sharedSecret: sharedSecret)
                }
              } catch {
                Logger.error("failed to enable encryption: \(error)")
              }
            }
          },
          onFailure: { error in
            Logger.error("join request for online server failed: \(error)")
          }
        )
      } else {
        Logger.error("cannot join online server with offline account")
        DeltaClientApp.triggerError("cannot join online server with offline account")
      }
    } else {
      Logger.error("not logged in")
      DeltaClientApp.triggerError("failed to join server: not logged in")
      return
    }
  }
}
