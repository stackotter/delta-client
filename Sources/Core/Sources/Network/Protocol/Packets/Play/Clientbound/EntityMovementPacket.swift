import Foundation

public struct EntityMovementPacket: ClientboundPacket, TickPacketMarker {
  public static let id: Int = 0x2b

  public var entityId: Int

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
  }

  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityVelocity.self) { velocity in
      velocity.vector = SIMD3<Double>.zero
    }
  }
}
