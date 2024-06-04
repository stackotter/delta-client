import Foundation

public struct EntityStatusPacket: ClientboundEntityPacket {
  public static let id: Int = 0x1b

  public var entityId: Int
  public var status: Status?

  // TODO: Add other statuses
  public enum Status: Int8 {
    case death = 3
  }

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readInt()
    status = Status(rawValue: try packetReader.readByte())
  }

  /// Should only be called if a nexus lock has already been acquired.
  public func handle(for client: Client) throws {
    if status == .death {
      // TODO: Play a death animation instead of instantly removing entities on death
      client.game.removeEntity(acquireLock: false, id: entityId)
    }
  }
}
