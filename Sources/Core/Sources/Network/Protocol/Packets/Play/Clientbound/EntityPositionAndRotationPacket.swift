import FirebladeMath
import Foundation

public struct EntityPositionAndRotationPacket: ClientboundEntityPacket {
  public static let id: Int = 0x29

  /// The entity's id.
  public var entityId: Int
  /// Change in x coordinate measured in 1/4096ths of a block.
  public var deltaX: Int16
  /// Change in y coordinate measured in 1/4096ths of a block.
  public var deltaY: Int16
  /// Change in z coordinate measured in 1/4096ths of a block.
  public var deltaZ: Int16
  /// The entity's new pitch.
  public var pitch: Float
  /// The entity's new yaw.
  public var yaw: Float
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    deltaX = try packetReader.readShort()
    deltaY = try packetReader.readShort()
    deltaZ = try packetReader.readShort()
    (pitch, yaw) = try packetReader.readEntityRotation()
    onGround = try packetReader.readBool()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    let x = Double(deltaX) / 4096
    let y = Double(deltaY) / 4096
    let z = Double(deltaZ) / 4096
    let relativePosition = Vec3d(x, y, z)

    client.game.accessEntity(id: entityId, acquireLock: false) { entity in
      guard
        let position = entity.get(component: EntityPosition.self),
        let lerpState = entity.get(component: EntityLerpState.self),
        let velocity = entity.get(component: EntityVelocity.self),
        let kind = entity.get(component: EntityKindId.self)?.entityKind,
        let onGroundComponent = entity.get(component: EntityOnGround.self)
      else {
        log.warning(
          "Entity '\(entityId)' is missing required components to handle \(Self.self)"
        )
        return
      }

      velocity.vector = .zero

      let currentTargetPosition = lerpState.currentLerp?.targetPosition ?? position.vector
      onGroundComponent.onGround = onGround
      lerpState.lerp(
        to: currentTargetPosition + relativePosition,
        pitch: pitch,
        yaw: yaw,
        duration: kind.defaultLerpDuration
      )
    }
  }
}
