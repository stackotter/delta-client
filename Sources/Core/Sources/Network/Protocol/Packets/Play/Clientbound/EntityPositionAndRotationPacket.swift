import Foundation

public struct EntityPositionAndRotationPacket: ClientboundPacket, TickPacketMarker {
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

  public func handle(for client: Client) throws {
    let x = Double(deltaX) / 4096
    let y = Double(deltaY) / 4096
    let z = Double(deltaZ) / 4096

    client.game.accessComponent(entityId: entityId, EntityPosition.self) { position in
      position.move(by: SIMD3<Double>(x, y, z))
    }

    client.game.accessComponent(entityId: entityId, EntityRotation.self) { rotation in
      rotation.pitch = pitch
      rotation.yaw = yaw
    }

    client.game.accessComponent(entityId: entityId, EntityOnGround.self) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }

    client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocity in
      if onGround {
        velocity.y = 0
      }
    }
  }
}
