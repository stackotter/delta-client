import FirebladeMath
import Foundation

public struct SpawnPlayerPacket: ClientboundPacket {
  public static let id: Int = 0x04

  /// The player's entity id.
  public var entityId: Int
  /// The player's UUID.
  public var playerUUID: UUID
  /// The player's position.
  public var position: Vec3d
  /// The player's pitch.
  public var pitch: Float
  /// The player's yaw.
  public var yaw: Float

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    playerUUID = try packetReader.readUUID()
    position = try packetReader.readEntityPosition()
    (pitch, yaw) = try packetReader.readEntityRotation()
  }

  public func handle(for client: Client) throws {
    let playerEntity = RegistryStore.shared.entityRegistry.playerEntityKind
    client.game.createEntity(id: entityId) {
      LivingEntity()
      PlayerEntity()
      EntityKindId(playerEntity.id)
      EntityId(entityId)
      EntityUUID(playerUUID)
      EntityHitBox(width: playerEntity.width, height: playerEntity.height)
      EntityOnGround(true)
      EntityPosition(position)
      EntityVelocity(0, 0, 0)
      EntityRotation(pitch: pitch, yaw: yaw)
      EntityLerpState()
      EntityAttributes()
    }
  }
}
