import Foundation
import FirebladeECS

public struct SpawnEntityPacket: ClientboundPacket {
  public static let id: Int = 0x00
  
  public var entityId: Int
  public var objectUUID: UUID
  public var type: Int
  public var position: EntityPosition
  public var rotation: EntityRotation
  public var data: Int
  public var velocity: EntityVelocity?
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    objectUUID = try packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    // seems a lil sus that this is the only packet that has pitch and yaw in the other order
    rotation = packetReader.readEntityRotation(pitchFirst: true)
    data = packetReader.readInt()
    
    velocity = nil
    if data > 0 {
      velocity = packetReader.readEntityVelocity()
    }
  }
  
  public func handle(for client: Client) throws {
    if let velocity = velocity {
      client.game.createEntity(id: entityId) {
        NonLivingEntity()
        EntityId(entityId)
        ObjectUUID(objectUUID)
        EntityKindId(type)
        EntityOnGround(true)
        data
        position
        rotation
        velocity
      }
    } else {
      client.game.createEntity(id: entityId) {
        NonLivingEntity()
        EntityId(entityId)
        ObjectUUID(objectUUID)
        EntityKindId(type)
        EntityOnGround(true)
        data
        position
        rotation
      }
    }
  }
}
