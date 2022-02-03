import Foundation

public struct EntityPositionPacket: ClientboundPacket {
  public static let id: Int = 0x28
  
  /// The entity's id.
  public var entityId: Int
  /// Change in x coordinate measured in 1/4096ths of a block.
  public var deltaX: Int16
  /// Change in y coordinate measured in 1/4096ths of a block.
  public var deltaY: Int16
  /// Change in z coordinate measured in 1/4096ths of a block.
  public var deltaZ: Int16
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool
  
  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    deltaX = packetReader.readShort()
    deltaY = packetReader.readShort()
    deltaZ = packetReader.readShort()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    let x = Double(deltaX) / 4096
    let y = Double(deltaY) / 4096
    let z = Double(deltaZ) / 4096
    
    client.game.accessComponent(entityId: entityId, EntityPosition.self) { position in
      position.move(by: SIMD3<Double>(x, y, z))
    }
    
    client.game.accessComponent(entityId: entityId, EntityOnGround.self) { onGroundComponent in
      onGroundComponent.onGround = onGround
    }
    
    if onGround {
      client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocity in
        velocity.y = 0
      }
    }
  }
}
