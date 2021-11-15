import Foundation

public struct SpawnLivingEntityPacket: ClientboundPacket {
  public static let id: Int = 0x02
  
  public var entityId: Int
  public var entityUUID: UUID
  public var type: Int
  public var position: SIMD3<Double>
  public var pitch: Float
  public var yaw: Float
  public var headYaw: Float
  public var velocity: SIMD3<Double>
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    entityUUID = try packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    (pitch, yaw) = packetReader.readEntityRotation()
    headYaw = packetReader.readAngle()
    velocity = packetReader.readEntityVelocity()
  }
  
  public func handle(for client: Client) {
    guard let entity = Registry.shared.entityRegistry.entity(withId: type) else {
      log.warning("Entity spawned with invalid type id: \(type)")
      return
    }
    
    client.game.createEntity(id: entityId) {
      LivingEntity() // Mark it as a living entity
      EntityKindId(type)
      EntityId(entityId)
      EntityUUID(entityUUID)
      EntityOnGround(true)
      EntityPosition(position)
      EntityVelocity(velocity)
      EntityHitBox(width: entity.width, height: entity.height)
      EntityRotation(pitch: pitch, yaw: yaw)
      EntityHeadYaw(headYaw)
    }
  }
}
