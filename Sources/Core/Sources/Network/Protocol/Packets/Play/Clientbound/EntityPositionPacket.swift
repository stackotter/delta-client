import Foundation
import FirebladeMath

public struct EntityPositionPacket: ClientboundEntityPacket {
  public static let id: Int = 0x28

  /// The entity's id.
  public var entityId: Int
  /// Change in x coordinate measured in 1/4096ths of a block.
  public var deltaX: Int16
  /// Change in y coordinate measured in 1/4096ths of a block.
  public var deltaY: Int16
  /// Change in z coordinate measured in 1/4096ths of a block.
  public var deltaZ: Int16
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    deltaX = try packetReader.readShort()
    deltaY = try packetReader.readShort()
    deltaZ = try packetReader.readShort()
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
        let rotation = entity.get(component: EntityRotation.self),
        let lerpState = entity.get(component: EntityLerpState.self),
        let velocity = entity.get(component: EntityVelocity.self),
        let kind = entity.get(component: EntityKindId.self)?.entityKind,
        let onGroundComponent = entity.get(component: EntityOnGround.self)
      else {
        return
      }

      velocity.vector = .zero

      // TODO: When lerping for a minecart, the velocity should get set to the relative
      //   position too.
      let currentTargetPosition = lerpState.currentLerp?.targetPosition ?? position.vector
      onGroundComponent.onGround = onGround
      lerpState.lerp(
        to: currentTargetPosition + relativePosition,
        pitch: rotation.pitch,
        yaw: rotation.yaw,
        duration: kind.defaultLerpDuration
      )
    }
  }
}
