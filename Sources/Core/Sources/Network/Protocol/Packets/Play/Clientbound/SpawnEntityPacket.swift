import Foundation
import FirebladeECS

public struct SpawnEntityPacket: ClientboundPacket {
  public static let id: Int = 0x00
  
  public var entityId: Int
  public var objectUUID: UUID
  public var type: Int
  public var position: SIMD3<Double>
  public var pitch: Float
  public var yaw: Float
  public var data: Int
  public var velocity: SIMD3<Double>?
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    objectUUID = try packetReader.readUUID()
    type = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    // Seems a lil sus that this is the only packet that has pitch and yaw in the other order
    (pitch, yaw) = packetReader.readEntityRotation(pitchFirst: true)
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
        EntityKindId(type)
        EntityId(entityId)
        ObjectUUID(objectUUID)
        ObjectData(data)
        EntityOnGround(true)
        EntityPosition(position)
        EntityVelocity(velocity)
        EntityRotation(pitch: pitch, yaw: yaw)
      }
    } else {
      client.game.createEntity(id: entityId) {
        NonLivingEntity()
        EntityKindId(type)
        EntityId(entityId)
        ObjectUUID(objectUUID)
        ObjectData(data)
        EntityOnGround(true)
        EntityPosition(position)
        EntityRotation(pitch: pitch, yaw: yaw)
      }
    }
  }
}
