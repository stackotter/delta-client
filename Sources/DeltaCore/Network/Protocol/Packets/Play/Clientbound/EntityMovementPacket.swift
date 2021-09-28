import Foundation

public struct EntityMovementPacket: ClientboundPacket {
  public static let id: Int = 0x2b
  
  public var entityId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
  }
}
