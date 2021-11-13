import Foundation

public struct EntityTeleportPacket: ClientboundPacket {
  public static let id: Int = 0x56
  
  /// The entity's id.
  public var entityId: Int
  /// The entity's new position.
  public var position: EntityPosition
  /// The entity's new rotation.
  public var rotation: EntityRotation
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    if let component = client.game.component(entityId: entityId, EntityPosition.self) {
      component.value = position
    }
    
    if let component = client.game.component(entityId: entityId, EntityRotation.self) {
      component.value = rotation
    }
    
    if let component = client.game.component(entityId: entityId, EntityOnGround.self) {
      component.value.onGround = onGround
    }
  }
}
