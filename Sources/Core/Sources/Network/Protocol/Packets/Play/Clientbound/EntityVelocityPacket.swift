import Foundation

public struct EntityVelocityPacket: ClientboundPacket {
  public static let id: Int = 0x46
  
  public var entityId: Int
  public var velocity: EntityVelocity

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    velocity = packetReader.readEntityVelocity()
  }
}
