import Foundation

public struct BlockChangePacket: ClientboundPacket {
  public static let id: Int = 0x0b
  
  public var location: BlockPosition
  public var blockId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    location = try packetReader.readBlockPosition()
    blockId = try packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.game.world.setBlockId(at: location, to: blockId)
  }
}
