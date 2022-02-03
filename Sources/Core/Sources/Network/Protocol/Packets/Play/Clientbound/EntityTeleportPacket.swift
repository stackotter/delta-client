import Foundation

public struct EntityTeleportPacket: ClientboundPacket {
  public static let id: Int = 0x56
  
  /// The entity's id.
  public var entityId: Int
  /// The entity's new position.
  public var position: SIMD3<Double>
  /// The entity's new pitch.
  public var pitch: Float
  /// The entity's new yaw.
  public var yaw: Float
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    (pitch, yaw) = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityPosition.self) { positionComponent in
      positionComponent.move(to: position)
    }
    
    client.game.accessComponent(entityId: entityId, EntityRotation.self) { rotation in
      rotation.pitch = pitch
      rotation.yaw = yaw
    }
    
    client.game.accessComponent(entityId: entityId, EntityOnGround.self) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }
    
    client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocity in
      velocity.vector = SIMD3<Double>.zero
    }
  }
}
