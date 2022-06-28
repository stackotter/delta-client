import Foundation

public struct EntityHeadLookPacket: ClientboundPacket, TickPacketMarker {
  public static let id: Int = 0x3b
  
  public var entityId: Int
  public var headYaw: Float

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    headYaw = try packetReader.readAngle()
  }
  
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityHeadYaw.self) { component in
      component.yaw = headYaw
    }
  }
}
