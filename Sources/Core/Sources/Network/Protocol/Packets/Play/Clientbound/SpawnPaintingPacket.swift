import Foundation

public struct SpawnPaintingPacket: ClientboundPacket {
  public static let id: Int = 0x03
  
  public var entityId: Int
  public var entityUUID: UUID
  public var motive: Int
  public var location: BlockPosition
  public var direction: UInt8 // TODO_LATER
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = try packetReader.readUUID()
    motive = packetReader.readVarInt()
    location = packetReader.readPosition()
    direction = packetReader.readUnsignedByte()
  }
}
