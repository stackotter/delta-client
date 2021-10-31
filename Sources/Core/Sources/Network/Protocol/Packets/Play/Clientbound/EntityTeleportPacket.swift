import Foundation

public struct EntityTeleportPacket: ClientboundPacket {
  public static let id: Int = 0x56
  
  public var entityId: Int
  public var position: EntityPosition
  public var rotation: EntityRotation
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
}
