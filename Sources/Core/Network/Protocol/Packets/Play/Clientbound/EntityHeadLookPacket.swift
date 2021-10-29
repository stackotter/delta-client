import Foundation

public struct EntityHeadLookPacket: ClientboundPacket {
  public static let id: Int = 0x3b
  
  public var entityId: Int
  public var headYaw: UInt8

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    headYaw = packetReader.readAngle()
  }
}
