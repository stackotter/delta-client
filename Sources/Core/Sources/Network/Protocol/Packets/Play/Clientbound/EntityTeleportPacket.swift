import Foundation

public struct EntityTeleportPacket: ClientboundPacket {
  public static let id: Int = 0x56
  
  /// The entity's id.
  public var entityId: Int
  /// The entity's new position.
  public var position: SIMD3<Double>
  /// The entity's new pitch.
  public var pitch: Float
  /// The entity's new yaw.
  public var yaw: Float
  /// Whether the entity is on the ground or not. See ``EntityOnGround``.
  public var onGround: Bool

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    position = packetReader.readEntityPosition()
    (pitch, yaw) = packetReader.readEntityRotation()
    onGround = packetReader.readBool()
  }
  
  public func handle(for client: Client) throws {
    if let positionComponent = client.game.component(entityId: entityId, EntityPosition.self) {
      positionComponent.move(to: position)
    }
    
    if let rotation = client.game.component(entityId: entityId, EntityRotation.self) {
      rotation.pitch = pitch
      rotation.yaw = yaw
    }
    
    if let onGroundComponent = client.game.component(entityId: entityId, EntityOnGround.self) {
      onGroundComponent.onGround = onGround
    }
    
    if let velocity = client.game.component(entityId: entityId, EntityVelocity.self) {
      velocity.vector = SIMD3<Double>.zero
    }
  }
}
