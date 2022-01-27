import Foundation

public struct BlockActionPacket: ClientboundPacket {
  public static let id: Int = 0x0a
  
  public var location: BlockPosition
  public var actionId: UInt8
  public var actionParam: UInt8
  public var blockType: Int // this is the block id not the block state
  
  public init(from packetReader: inout PacketReader) throws {
    location = packetReader.readPosition()
    actionId = packetReader.readUnsignedByte()
    actionParam = packetReader.readUnsignedByte()
    blockType = packetReader.readVarInt()
  }
}
