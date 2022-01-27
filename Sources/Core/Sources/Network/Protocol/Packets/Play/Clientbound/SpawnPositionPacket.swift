import Foundation

public struct SpawnPositionPacket: ClientboundPacket {
  public static let id: Int = 0x42
  
  public var location: BlockPosition

  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessPlayer { player in
      player.attributes.spawnPosition = location
    }
    
    log.info("Finished downloading terrain")
    client.eventBus.dispatch(TerrainDownloadCompletionEvent())
    
    // notify server that we are ready to finish login
    let clientStatus = ClientStatusPacket(action: .performRespawn)
    try client.sendPacket(clientStatus)
  }
}
