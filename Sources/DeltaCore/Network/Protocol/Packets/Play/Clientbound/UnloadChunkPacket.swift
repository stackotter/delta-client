import Foundation

public struct UnloadChunkPacket: ClientboundPacket {
  public static let id: Int = 0x1d
  
  public var chunkPosition: ChunkPosition
  
  public init(from packetReader: inout PacketReader) throws {
    let chunkX = Int(packetReader.readInt())
    let chunkZ = Int(packetReader.readInt())
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  public func handle(for client: Client) {
    client.server?.world.removeChunk(at: chunkPosition)
  }
}
