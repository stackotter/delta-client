import Foundation

public struct BlockChangePacket: ClientboundPacket {
  public static let id: Int = 0x0b
  
  public var location: Position
  public var blockId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    blockId = packetReader.readVarInt()
  }
  
  public func handle(for client: Client) throws {
    client.server?.world.setBlockId(at: location, to: blockId)
  }
}
