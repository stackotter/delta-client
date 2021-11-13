import Foundation

public struct EntityRotationPacket: ClientboundPacket {
  public static let id: Int = 0x2a

  /// The entity's id.
  public var entityId: Int
  /// The entity's new rotation.
  public var rotation: EntityRotation
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    if let component = client.game.component(entityId: entityId, EntityRotation.self) {
      component.value = rotation
    }
    
    if let component = client.game.component(entityId: entityId, EntityOnGround.self) {
      component.value.onGround = onGround
    }
  }
}
