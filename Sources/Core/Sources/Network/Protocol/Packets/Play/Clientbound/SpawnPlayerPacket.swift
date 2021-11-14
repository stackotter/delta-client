import Foundation

public struct SpawnPlayerPacket: ClientboundPacket {
  public static let id: Int = 0x04
  
  /// The player's entity id.
  public var entityId: Int
  /// The player's UUID.
  public var playerUUID: UUID
  /// The player's position.
  public var position: EntityPosition
  /// The player's rotation.
  public var rotation: EntityRotation
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    playerUUID = try packetReader.readUUID()
    position = packetReader.readEntityPosition()
    rotation = packetReader.readEntityRotation()
  }
  
  public func handle(for client: Client) throws {
    client.game.createEntity(id: entityId) {
      PlayerEntity()
      EntityKindId(Registry.shared.entityRegistry.identifierToEntityId[Identifier(name: "player")]!)
      
      EntityId(entityId)
      EntityUUID(playerUUID)
      
      EntityOnGround(true)
      position
      EntityVelocity(x: 0.0, y: 0.0, z: 0.0)
      rotation
    }
  }
}
