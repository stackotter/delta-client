import Foundation

public struct EntityPositionAndRotationPacket: ClientboundPacket {
  public static let id: Int = 0x29
  
  /// The entity's id.
  public var entityId: Int
  /// Change in x coordinate measured in 1/4096ths of a block.
  public var deltaX: Int16
  /// Change in y coordinate measured in 1/4096ths of a block.
  public var deltaY: Int16
  /// Change in z coordinate measured in 1/4096ths of a block.
  public var deltaZ: Int16
  /// The entity's new rotation.
  public var rotation: EntityRotation
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    rotation = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    let x = Double(deltaX) / 4096
    let y = Double(deltaY) / 4096
    let z = Double(deltaZ) / 4096
    
    if let position = client.game.component(entityId: entityId, EntityPosition.self) {
      position.value.move(by: SIMD3<Double>(x, y, z))
    }
    
    if let component = client.game.component(entityId: entityId, EntityRotation.self) {
      component.value = rotation
    }
    
    if let component = client.game.component(entityId: entityId, EntityOnGround.self) {
      component.value.onGround = onGround
    }
    
    if let component = client.game.component(entityId: entityId, EntityVelocity.self) {
      if onGround {
        component.value.y = 0
      }
    }
  }
}
