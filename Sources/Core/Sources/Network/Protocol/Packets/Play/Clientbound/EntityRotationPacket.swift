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
    client.game.accessComponent(entityId: entityId, EntityRotation.self, acquireLock: false) { rotation in
      rotation.pitch = pitch
      rotation.yaw = yaw
    }

    client.game.accessComponent(entityId: entityId, EntityOnGround.self, acquireLock: false) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }

    if onGround {
      client.game.accessComponent(entityId: entityId, EntityVelocity.self, acquireLock: false) { velocity in
        velocity.y = 0
      }
    }
  }
}
