import Foundation

public struct EntityMovementPacket: ClientboundEntityPacket {
  public static let id: Int = 0x2b

  public var entityId: Int

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()
  }

  /// Should only be called if a nexus write lock is already acquired.
  public func handle(for client: Client) throws {
    client.game.accessComponent(entityId: entityId, EntityVelocity.self, acquireLock: false) { velocity in
      velocity.vector = SIMD3<Double>.zero
    }
  }
}
