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

    client.game.accessComponent(entityId: entityId, EntityPosition.self, acquireLock: false) { position in
      position.move(by: relativePosition)
    }

    client.game.accessComponent(entityId: entityId, EntityOnGround.self, acquireLock: false) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }

    client.game.accessComponent(entityId: entityId, EntityVelocity.self, acquireLock: false) { velocity in
      velocity.vector = .zero
    }
  }
}
