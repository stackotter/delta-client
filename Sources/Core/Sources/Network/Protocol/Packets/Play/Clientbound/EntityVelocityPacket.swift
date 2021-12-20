import Foundation

public struct EntityVelocityPacket: ClientboundPacket {
  public static let id: Int = 0x46
  
  /// The entity's id.
  public var entityId: Int
  /// The entity's new velocity.
  public var velocity: SIMD3<Double>

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    velocity = packetReader.readEntityVelocity()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocityComponent in
      velocityComponent.vector = velocity
    }
  }
}
