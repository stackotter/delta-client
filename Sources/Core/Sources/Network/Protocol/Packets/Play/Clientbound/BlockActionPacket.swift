import Foundation

public struct BlockActionPacket: ClientboundPacket {
  public static let id: Int = 0x0a
  
  public var location: BlockPosition
  public var actionId: UInt8
  public var actionParam: UInt8
  public var blockType: Int // this is the block id not the block state
  
  public init(from packetReader: inout PacketReader) throws {
    location = try packetReader.readBlockPosition()
    actionId = try packetReader.readUnsignedByte()
    actionParam = try packetReader.readUnsignedByte()
    blockType = try packetReader.readVarInt()
  }
}
