import Foundation

public struct AcknowledgePlayerDiggingPacket: ClientboundPacket {
  public static let id: Int = 0x07
  
  public var location: BlockPosition
  public var block: Int
  public var status: Int
  public var successful: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    location = try packetReader.readBlockPosition()
    block = try packetReader.readVarInt()
    status = try packetReader.readVarInt()
    successful = try packetReader.readBool()
  }
}
