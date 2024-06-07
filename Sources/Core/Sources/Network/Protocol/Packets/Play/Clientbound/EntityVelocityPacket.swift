import FirebladeMath
import Foundation

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
    client.game.accessComponent(
      entityId: entityId,
      EntityVelocity.self,
      acquireLock: false
    ) { velocityComponent in
      // I think this packet is the cause of most of our weird entity behaviour
      // TODO: Figure out why handling velocity is causing entities to drift (observe spiders for a while
      //   to reproduce issue). Works best if spider is trying to climb a wall but it stuck under a roof.
      velocityComponent.vector = velocity
    }
  }
}
