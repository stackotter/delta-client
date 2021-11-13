import Foundation

public struct EntityHeadLookPacket: ClientboundPacket {
  public static let id: Int = 0x3b
  
  public var entityId: Int
  public var headYaw: Float

  public init(from packetReader: inout PacketReader) throws {
    entityId = packetReader.readVarInt()
    headYaw = packetReader.readAngle()
  }
  
  public func handle(for client: Client) throws {
    if let component = client.game.component(entityId: entityId, EntityHeadYaw.self) {
      component.value.yaw = headYaw
    }
  }
}
