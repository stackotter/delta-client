import Foundation

public enum EncryptionRequestPacketError: LocalizedError {
  case incorrectAccountType
  case noAccount
}

public struct EncryptionRequestPacket: ClientboundPacket, Sendable {
  public static let id: Int = 0x01
  
  public let serverId: String
  public let publicKey: [UInt8]
  public let verifyToken: [UInt8]

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
    
    // Calculate the server hash
    let serverHash = CryptoUtil.sha1MojangDigest([
      serverIdData,
      Data(sharedSecret),
      Data(publicKey)
    ])
    
    // TODO: Clean up EncryptionRequestPacket.handle
    // Request to join the server
    if let account = client.account?.online {
      let accessToken = account.accessToken
      let selectedProfile = account.id
      
      Task {
        do {
          try await MojangAPI.join(
            accessToken: accessToken.token,
            selectedProfile: selectedProfile,
            serverHash: serverHash)
        } catch {
          log.error("Join request for online server failed: \(error)")
          client.eventBus.dispatch(PacketHandlingErrorEvent(packetId: Self.id, error: "Join request for online server failed: \(error)"))
          return
        }
        
        // block inbound thread until encryption is enabled
        client.connection?.networkStack.inboundThread.sync {
          do {
            let publicKeyData = Data(publicKey)
            
            // Send encryption response packet
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
            
            // Wait for packet to send then enable encryption
            client.connection?.networkStack.outboundThread.sync {
              client.connection?.enableEncryption(sharedSecret: sharedSecret)
            }
          } catch {
            log.error("Failed to enable encryption: \(error)")
          }
        }
      }
    } else {
      log.error("Cannot join an online server with an offline account")
      throw EncryptionRequestPacketError.incorrectAccountType
    }
  }
}
