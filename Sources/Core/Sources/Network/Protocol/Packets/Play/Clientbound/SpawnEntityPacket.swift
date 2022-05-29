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
    entityId = try packetReader.readVarInt()
    objectUUID = try packetReader.readUUID()
    type = try packetReader.readVarInt()
    position = try packetReader.readEntityPosition()
    // Seems a lil sus that this is the only packet that has pitch and yaw in the other order
    (pitch, yaw) = try packetReader.readEntityRotation(pitchFirst: true)
    data = try packetReader.readInt()
    
    if data > 0 {
      velocity = try packetReader.readEntityVelocity()
    }
  }
  
  public func handle(for client: Client) throws {
    guard let entityKind = RegistryStore.shared.entityRegistry.entity(withId: type) else {
      log.warning("Ignored entity received with unknown type: \(type)")
      return
    }
    
    // TODO: implement if statements for component builder
    if let velocity = velocity {
      client.game.createEntity(id: entityId) {
        NonLivingEntity()
        EntityKindId(type)
        EntityId(entityId)
        ObjectUUID(objectUUID)
        ObjectData(data)
        EntityHitBox(width: entityKind.width, height: entityKind.height)
        EntityOnGround(true)
        EntityPosition(position)
        EntityVelocity(velocity)
        EntityRotation(pitch: pitch, yaw: yaw)
        EntityAttributes()
      }
    } else {
      client.game.createEntity(id: entityId) {
        NonLivingEntity()
        EntityKindId(type)
        EntityId(entityId)
        ObjectUUID(objectUUID)
        ObjectData(data)
        EntityHitBox(width: entityKind.width, height: entityKind.height)
        EntityOnGround(true)
        EntityPosition(position)
        EntityRotation(pitch: pitch, yaw: yaw)
        EntityAttributes()
      }
    }
  }
}
