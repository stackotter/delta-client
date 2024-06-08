import FirebladeMath
import Foundation

public struct SpawnLivingEntityPacket: ClientboundPacket {
  public static let id: Int = 0x02

  public var entityId: Int
  public var entityUUID: UUID
  public var type: Int
  public var position: Vec3d
  public var pitch: Float
  public var yaw: Float
  public var headYaw: Float
  public var velocity: Vec3d

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    entityUUID = try packetReader.readUUID()
    type = try packetReader.readVarInt()
    position = try packetReader.readEntityPosition()
    (pitch, yaw) = try packetReader.readEntityRotation()
    headYaw = try packetReader.readAngle()
    velocity = try packetReader.readEntityVelocity()
  }

  public func handle(for client: Client) {
    guard let entityKind = RegistryStore.shared.entityRegistry.entity(withId: type) else {
      log.warning("Entity spawned with invalid type id: \(type)")
      return
    }

    if entityKind.isEnderDragon {
      client.game.createEntity(id: entityId) {
        LivingEntity()  // Mark it as a living entity
        EntityKindId(type)
        EntityId(entityId)
        EntityUUID(entityUUID)
        EntityOnGround(true)
        EntityPosition(position)
        EntityVelocity(velocity)
        EntityHitBox(width: entityKind.width, height: entityKind.height)
        EntityRotation(pitch: pitch, yaw: yaw)
        EntityHeadYaw(headYaw)
        EntityLerpState()
        EntityAttributes()
        EntityMetadata(inheritanceChain: entityKind.inheritanceChain)
        EnderDragonParts()
      }
    } else {
      client.game.createEntity(id: entityId) {
        LivingEntity()  // Mark it as a living entity
        EntityKindId(type)
        EntityId(entityId)
        EntityUUID(entityUUID)
        EntityOnGround(true)
        EntityPosition(position)
        EntityVelocity(velocity)
        EntityHitBox(width: entityKind.width, height: entityKind.height)
        EntityRotation(pitch: pitch, yaw: yaw)
        EntityHeadYaw(headYaw)
        EntityLerpState()
        EntityAttributes()
        EntityMetadata(inheritanceChain: entityKind.inheritanceChain)
      }
    }
  }
}
