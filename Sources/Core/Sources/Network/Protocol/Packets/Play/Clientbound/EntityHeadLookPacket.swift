import Foundation

public struct EntityHeadLookPacket: ClientboundEntityPacket {
  public static let id: Int = 0x3b

  public var entityId: Int
  public var headYaw: Float

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
    headYaw = try packetReader.readAngle()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityHeadYaw.self, acquireLock: false) { component in
      component.yaw = headYaw
    }
  }
}
