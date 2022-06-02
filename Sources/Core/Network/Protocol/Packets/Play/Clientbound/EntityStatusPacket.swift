import Foundation

public struct EntityStatusPacket: ClientboundPacket {
  public static let id: Int = 0x1b
  
  public var entityId: Int
  public var status: Int8
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readInt()
    status = try packetReader.readByte()
  }
}
