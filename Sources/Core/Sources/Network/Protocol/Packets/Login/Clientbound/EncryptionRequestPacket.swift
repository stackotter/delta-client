import Foundation

public enum EncryptionRequestPacketError: LocalizedError {
  case incorrectAccountType
  case noAccount
}

public struct EncryptionRequestPacket: ClientboundPacket {
  public static let id: Int = 0x01
  
  public var serverId: String
  public var publicKey: [UInt8]
  public var verifyToken: [UInt8]

  public init(from packetReader: inout PacketReader) throws {
    serverId = try packetReader.readString()
    
    let publicKeyLength = packetReader.readVarInt()
    publicKey = packetReader.readByteArray(length: publicKeyLength)
    
    let verifyTokenLength = packetReader.readVarInt()
    verifyToken = packetReader.readByteArray(length: verifyTokenLength)
  }
  
  public func handle(for client: Client) throws {
	  
    client.eventBus.dispatch(LoginStartEvent())
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
    
    // TODO: Clean up EncryptionRequestPacket.handle
    if let mojangAccount = client.account as? MojangAccount {
      let accessToken = mojangAccount.accessToken
      let selectedProfile = mojangAccount.profileId
      MojangAPI.join(
        accessToken: accessToken,
        selectedProfile: selectedProfile,
        serverHash: serverHash,
        onCompletion: {
          // block inbound thread until encryption is enabled
          client.connection?.networkStack.inboundThread.sync {
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
              try client.sendPacket(encryptionResponse)
              
              // wait for packet to send then enable encryption
              client.connection?.networkStack.outboundThread.sync {
                client.connection?.enableEncryption(sharedSecret: sharedSecret)
              }
            } catch {
              log.error("Failed to enable encryption: \(error.localizedDescription)")
            }
          }
        },
        onFailure: { error in
          log.error("Join request for online server failed: \(error.localizedDescription)")
        }
      )
    } else {
      log.error("Cannot join an online server with an offline account")
      throw EncryptionRequestPacketError.incorrectAccountType
    }
  }
}
