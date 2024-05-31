import Foundation

public struct EntityRotationPacket: ClientboundEntityPacket {
  public static let id: Int = 0x2a

  /// The entity's id.
  public var entityId: Int
  /// The entity's new pitch.
  public var pitch: Float
  /// The entity's new yaw.
  public var yaw: Float
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    (pitch, yaw) = try packetReader.readEntityRotation()
    onGround = try packetReader.readBool()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    client.game.accessEntity(id: entityId, acquireLock: false) { entity in
      guard
        let position = entity.get(component: EntityPosition.self),
        let lerpState = entity.get(component: EntityLerpState.self),
        let kind = entity.get(component: EntityKindId.self)?.entityKind,
        let onGroundComponent = entity.get(component: EntityOnGround.self)
      else {
        return
      }

      let currentTargetPosition = lerpState.currentLerp?.targetPosition ?? position.vector
      onGroundComponent.onGround = onGround
      lerpState.lerp(
        to: currentTargetPosition,
        pitch: pitch,
        yaw: yaw,
        duration: kind.defaultLerpDuration
      )
    }
  }
}
