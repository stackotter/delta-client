import Foundation
import FirebladeMath

public struct EntityTeleportPacket: ClientboundEntityPacket {
  public static let id: Int = 0x56

  /// The entity's id.
  public var entityId: Int
  /// The entity's new position.
  public var position: Vec3d
  /// The entity's new pitch.
  public var pitch: Float
  /// The entity's new yaw.
  public var yaw: Float
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    position = try packetReader.readEntityPosition()
    (pitch, yaw) = try packetReader.readEntityRotation()
    onGround = try packetReader.readBool()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    client.game.accessEntity(id: entityId, acquireLock: false) { entity in
      guard
        let lerpState = entity.get(component: EntityLerpState.self),
        let velocity = entity.get(component: EntityVelocity.self),
        let kind = entity.get(component: EntityKindId.self)?.entityKind,
        let onGroundComponent = entity.get(component: EntityOnGround.self)
      else {
        return
      }

      velocity.vector = .zero

      onGroundComponent.onGround = onGround
      lerpState.lerp(
        to: position,
        pitch: pitch,
        yaw: yaw,
        duration: kind.defaultLerpDuration
      )
    }
  }
}
