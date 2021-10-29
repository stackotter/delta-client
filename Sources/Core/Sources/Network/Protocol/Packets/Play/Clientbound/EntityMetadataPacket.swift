import Foundation

public struct EntityMetadataPacket: ClientboundPacket {
  public static let id: Int = 0x44
  
  public var entityId: Int

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    // IMPLEMENT: the rest of this packet
  }
}
