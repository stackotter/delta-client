import Foundation

public struct KeepAliveServerBoundPacket: ServerboundPacket {
  public static let id: Int = 0x10
  
  public var keepAliveId: Int
  
  public func writePayload(to writer: inout PacketWriter) {
    writer.writeLong(Int64(keepAliveId))
  }
}
