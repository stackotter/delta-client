import Foundation

public struct EntityVelocityPacket: ClientboundPacket {
  public static let id: Int = 0x46
  
  /// The entity's id.
  public var entityId: Int
  /// The entity's new velocity.
  public var velocity: EntityVelocity

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    velocity = packetReader.readEntityVelocity()
  }
  
  public func handle(for client: Client) throws {
    if let component = client.game.component(entityId: entityId, EntityVelocity.self) {
      component.value = velocity
    }
  }
}
