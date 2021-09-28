import Foundation

public struct SpawnLivingEntity: ClientboundPacket {
  public static let id: Int = 0x02
  
  public var entityId: Int
  public var entityUUID: UUID
  public var type: Int
  public var position: EntityPosition
  public var rotation: EntityRotation
  public var headPitch: UInt8
  public var velocity: EntityVelocity
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = try packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
    headPitch = packetReader.readAngle()
    velocity = packetReader.readEntityVelocity()
  }
}
