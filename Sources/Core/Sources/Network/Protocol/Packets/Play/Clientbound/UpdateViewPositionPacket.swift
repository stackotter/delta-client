import Foundation

public struct UpdateViewPositionPacket: ClientboundPacket {
  public static let id: Int = 0x40
  
  public var chunkPosition: ChunkPosition
  
  public init(from packetReader: inout PacketReader) {
    let chunkX = Int(packetReader.readVarInt())
    let chunkZ = Int(packetReader.readVarInt())
    chunkPosition = ChunkPosition(chunkX: chunkX, chunkZ: chunkZ)
  }
  
  public func handle(for client: Client) throws {
    // TODO: trigger world to recalculate which chunks should be rendered (if a circle is decided on for chunk rendering)
  }
}
