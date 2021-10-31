import Foundation

public struct TimeUpdatePacket: ClientboundPacket {
  public static let id: Int = 0x4e
  
  public var worldAge: Int
  public var timeOfDay: Int

  public init(from packetReader: inout PacketReader) throws {
    worldAge = packetReader.readLong()
    timeOfDay = packetReader.readLong()
  }
  
  public func handle(for client: Client) throws {
    client.game.world.updateTime(with: self)
  }
}
