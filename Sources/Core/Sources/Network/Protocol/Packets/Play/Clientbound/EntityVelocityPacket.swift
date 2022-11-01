import Foundation
import FirebladeMath

public struct EntityVelocityPacket: ClientboundEntityPacket {
  public static let id: Int = 0x46

  /// The entity's id.
  public var entityId: Int
  /// The entity's new velocity.
  public var velocity: Vec3d

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    velocity = try packetReader.readEntityVelocity()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityVelocity.self, acquireLock: false) { velocityComponent in
      velocityComponent.vector = velocity
    }
  }
}
