import Foundation

public struct EntityRotationPacket: ClientboundPacket {
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
    entityId = packetReader.readVarInt()
    (pitch, yaw) = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityRotation.self) { rotation in
      rotation.pitch = pitch
      rotation.yaw = yaw
    }
    
    client.game.accessComponent(entityId: entityId, EntityOnGround.self) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }
    
    if onGround {
      client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocity in
        velocity.y = 0
      }
    }
  }
}
