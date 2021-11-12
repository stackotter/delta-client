import Foundation

public struct SpawnLivingEntityPacket: ClientboundPacket {
  public static let id: Int = 0x02
  
  public var entityId: Int
  public var entityUUID: UUID
  public var type: Int
  public var position: EntityPosition
  public var rotation: EntityRotation
  public var headPitch: Float
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
  
  public func handle(for client: Client) {
    let entityKind: EntityKind
    guard type < Registry.shared.entityRegistry.entities.count && type >= 0 else {
      log.warning("Entity spawned with invalid type id: \(type)")
      return
    }
    
    let entity = client.game.nexus.createEntity {
      Box(LivingEntity()) // Mark it as a living entity
      Box(EntityId(entityId))
      Box(EntityUUID(entityUUID))
      Box(EntityKindId(type))
      Box(position)
      Box(rotation)
      Box(velocity)
      Box(EntityHeadPitch(headPitch))
    }
  }
}
