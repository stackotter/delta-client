import Foundation

public struct KeepAliveClientboundPacket: ClientboundPacket {
  public static let id: Int = 0x20
  
  public var keepAliveId: Int
  
  public init(from packetReader: inout PacketReader) throws {
    keepAliveId = try packetReader.readLong()
  }
  
  public func handle(for client: Client) throws {
    let keepAlive = KeepAliveServerBoundPacket(keepAliveId: keepAliveId)
    try client.sendPacket(keepAlive)
  }
}
